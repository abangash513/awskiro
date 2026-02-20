"""Notification service for budget alerts and system events."""

import asyncio
import json
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Optional

import httpx

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class NotificationChannel(str, Enum):
    """Supported notification channels."""
    
    EMAIL = "email"
    WEBHOOK = "webhook"
    SLACK = "slack"
    TEAMS = "teams"


class NotificationSeverity(str, Enum):
    """Notification severity levels."""
    
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


@dataclass
class NotificationPayload:
    """Standard notification payload."""
    
    title: str
    message: str
    severity: NotificationSeverity
    source: str = "cloudoptima"
    timestamp: datetime = field(default_factory=datetime.utcnow)
    metadata: dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary."""
        return {
            "title": self.title,
            "message": self.message,
            "severity": self.severity.value,
            "source": self.source,
            "timestamp": self.timestamp.isoformat(),
            "metadata": self.metadata,
        }


@dataclass
class BudgetAlertPayload(NotificationPayload):
    """Budget-specific alert payload."""
    
    budget_id: Optional[int] = None
    budget_name: Optional[str] = None
    threshold_percent: Optional[int] = None
    actual_percent: Optional[float] = None
    actual_amount: Optional[float] = None
    budget_amount: Optional[float] = None
    currency: str = "USD"
    
    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary with budget details."""
        data = super().to_dict()
        data.update({
            "budget": {
                "id": self.budget_id,
                "name": self.budget_name,
                "threshold_percent": self.threshold_percent,
                "actual_percent": self.actual_percent,
                "actual_amount": self.actual_amount,
                "budget_amount": self.budget_amount,
                "currency": self.currency,
            }
        })
        return data


class NotificationProvider(ABC):
    """Abstract base class for notification providers."""
    
    @property
    @abstractmethod
    def channel(self) -> NotificationChannel:
        """Return the notification channel type."""
        pass
    
    @abstractmethod
    async def send(self, payload: NotificationPayload) -> bool:
        """
        Send a notification.
        
        Args:
            payload: Notification payload
            
        Returns:
            True if successful, False otherwise
        """
        pass
    
    @abstractmethod
    def is_configured(self) -> bool:
        """Check if provider is properly configured."""
        pass


class WebhookProvider(NotificationProvider):
    """Generic webhook notification provider."""
    
    def __init__(
        self,
        webhook_url: Optional[str] = None,
        headers: Optional[dict[str, str]] = None,
        timeout: float = 10.0,
    ) -> None:
        """
        Initialize webhook provider.
        
        Args:
            webhook_url: Target webhook URL
            headers: Additional headers to include
            timeout: Request timeout in seconds
        """
        settings = get_settings()
        self._url = webhook_url or getattr(settings, "notification_webhook_url", None)
        self._headers = headers or {}
        self._timeout = timeout
    
    @property
    def channel(self) -> NotificationChannel:
        return NotificationChannel.WEBHOOK
    
    def is_configured(self) -> bool:
        return bool(self._url)
    
    async def send(self, payload: NotificationPayload) -> bool:
        if not self.is_configured():
            logger.warning("Webhook not configured, skipping notification")
            return False
        
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    self._url,
                    json=payload.to_dict(),
                    headers={
                        "Content-Type": "application/json",
                        "User-Agent": "CloudOptima-AI/1.0",
                        **self._headers,
                    },
                )
                
                if response.status_code < 300:
                    logger.info(
                        "Webhook notification sent",
                        url=self._url[:50] + "...",
                        status=response.status_code,
                    )
                    return True
                else:
                    logger.error(
                        "Webhook notification failed",
                        status=response.status_code,
                        response=response.text[:200],
                    )
                    return False
                    
        except httpx.TimeoutException:
            logger.error("Webhook notification timed out", url=self._url[:50])
            return False
        except Exception as e:
            logger.error("Webhook notification error", error=str(e))
            return False


class SlackProvider(NotificationProvider):
    """Slack notification provider using incoming webhooks."""
    
    SEVERITY_COLORS = {
        NotificationSeverity.INFO: "#36a64f",      # Green
        NotificationSeverity.WARNING: "#ff9800",   # Orange
        NotificationSeverity.CRITICAL: "#f44336",  # Red
    }
    
    def __init__(
        self,
        webhook_url: Optional[str] = None,
        channel: Optional[str] = None,
    ) -> None:
        """
        Initialize Slack provider.
        
        Args:
            webhook_url: Slack incoming webhook URL
            channel: Override channel (optional)
        """
        settings = get_settings()
        self._url = webhook_url or getattr(settings, "slack_webhook_url", None)
        self._channel = channel
    
    @property
    def channel(self) -> NotificationChannel:
        return NotificationChannel.SLACK
    
    def is_configured(self) -> bool:
        return bool(self._url)
    
    def _format_payload(self, payload: NotificationPayload) -> dict[str, Any]:
        """Format payload for Slack."""
        color = self.SEVERITY_COLORS.get(payload.severity, "#808080")
        
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"🔔 {payload.title}",
                    "emoji": True,
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": payload.message,
                }
            },
        ]
        
        # Add budget details if present
        if isinstance(payload, BudgetAlertPayload) and payload.budget_name:
            blocks.append({
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Budget:*\n{payload.budget_name}",
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Threshold:*\n{payload.threshold_percent}%",
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Current Spend:*\n{payload.currency} {payload.actual_amount:,.2f}",
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Budget Amount:*\n{payload.currency} {payload.budget_amount:,.2f}",
                    },
                ]
            })
        
        blocks.append({
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": f"Severity: *{payload.severity.value.upper()}* | {payload.timestamp.strftime('%Y-%m-%d %H:%M:%S UTC')}",
                }
            ]
        })
        
        slack_payload = {
            "attachments": [
                {
                    "color": color,
                    "blocks": blocks,
                }
            ]
        }
        
        if self._channel:
            slack_payload["channel"] = self._channel
        
        return slack_payload
    
    async def send(self, payload: NotificationPayload) -> bool:
        if not self.is_configured():
            logger.warning("Slack webhook not configured, skipping notification")
            return False
        
        try:
            slack_payload = self._format_payload(payload)
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    self._url,
                    json=slack_payload,
                    headers={"Content-Type": "application/json"},
                )
                
                if response.status_code == 200 and response.text == "ok":
                    logger.info("Slack notification sent", title=payload.title)
                    return True
                else:
                    logger.error(
                        "Slack notification failed",
                        status=response.status_code,
                        response=response.text[:200],
                    )
                    return False
                    
        except Exception as e:
            logger.error("Slack notification error", error=str(e))
            return False


class TeamsProvider(NotificationProvider):
    """Microsoft Teams notification provider using incoming webhooks."""
    
    SEVERITY_COLORS = {
        NotificationSeverity.INFO: "00FF00",      # Green
        NotificationSeverity.WARNING: "FFA500",   # Orange
        NotificationSeverity.CRITICAL: "FF0000",  # Red
    }
    
    def __init__(self, webhook_url: Optional[str] = None) -> None:
        """
        Initialize Teams provider.
        
        Args:
            webhook_url: Teams incoming webhook URL
        """
        settings = get_settings()
        self._url = webhook_url or getattr(settings, "teams_webhook_url", None)
    
    @property
    def channel(self) -> NotificationChannel:
        return NotificationChannel.TEAMS
    
    def is_configured(self) -> bool:
        return bool(self._url)
    
    def _format_payload(self, payload: NotificationPayload) -> dict[str, Any]:
        """Format payload for Teams Adaptive Card."""
        color = self.SEVERITY_COLORS.get(payload.severity, "808080")
        
        facts = [
            {"title": "Severity", "value": payload.severity.value.upper()},
            {"title": "Time", "value": payload.timestamp.strftime('%Y-%m-%d %H:%M:%S UTC')},
        ]
        
        if isinstance(payload, BudgetAlertPayload):
            facts.extend([
                {"title": "Budget", "value": payload.budget_name or "N/A"},
                {"title": "Threshold", "value": f"{payload.threshold_percent}%"},
                {"title": "Current Spend", "value": f"{payload.currency} {payload.actual_amount:,.2f}"},
                {"title": "Budget Amount", "value": f"{payload.currency} {payload.budget_amount:,.2f}"},
            ])
        
        return {
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "themeColor": color,
            "summary": payload.title,
            "sections": [
                {
                    "activityTitle": f"🔔 {payload.title}",
                    "activitySubtitle": "CloudOptima Budget Alert",
                    "facts": facts,
                    "markdown": True,
                    "text": payload.message,
                }
            ],
        }
    
    async def send(self, payload: NotificationPayload) -> bool:
        if not self.is_configured():
            logger.warning("Teams webhook not configured, skipping notification")
            return False
        
        try:
            teams_payload = self._format_payload(payload)
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    self._url,
                    json=teams_payload,
                    headers={"Content-Type": "application/json"},
                )
                
                if response.status_code == 200:
                    logger.info("Teams notification sent", title=payload.title)
                    return True
                else:
                    logger.error(
                        "Teams notification failed",
                        status=response.status_code,
                        response=response.text[:200],
                    )
                    return False
                    
        except Exception as e:
            logger.error("Teams notification error", error=str(e))
            return False


class NotificationService:
    """
    Central notification service that manages multiple providers.
    
    Usage:
        service = NotificationService()
        service.add_provider(SlackProvider("https://hooks.slack.com/..."))
        service.add_provider(WebhookProvider("https://my-webhook.example.com"))
        
        await service.send_budget_alert(
            budget_id=1,
            budget_name="Production",
            threshold=80,
            actual_percent=85.5,
            ...
        )
    """
    
    def __init__(self) -> None:
        """Initialize notification service."""
        self._providers: list[NotificationProvider] = []
        self._initialize_default_providers()
    
    def _initialize_default_providers(self) -> None:
        """Initialize providers from settings."""
        settings = get_settings()
        
        # Webhook
        if hasattr(settings, "notification_webhook_url") and settings.notification_webhook_url:
            self.add_provider(WebhookProvider())
        
        # Slack
        if hasattr(settings, "slack_webhook_url") and settings.slack_webhook_url:
            self.add_provider(SlackProvider())
        
        # Teams
        if hasattr(settings, "teams_webhook_url") and settings.teams_webhook_url:
            self.add_provider(TeamsProvider())
    
    def add_provider(self, provider: NotificationProvider) -> None:
        """
        Add a notification provider.
        
        Args:
            provider: Notification provider instance
        """
        if provider.is_configured():
            self._providers.append(provider)
            logger.info(
                "Notification provider added",
                channel=provider.channel.value,
            )
        else:
            logger.warning(
                "Notification provider not configured, skipping",
                channel=provider.channel.value,
            )
    
    def remove_provider(self, channel: NotificationChannel) -> None:
        """
        Remove all providers for a channel.
        
        Args:
            channel: Channel to remove
        """
        self._providers = [p for p in self._providers if p.channel != channel]
    
    @property
    def configured_channels(self) -> list[NotificationChannel]:
        """Get list of configured channels."""
        return list(set(p.channel for p in self._providers))
    
    async def send(
        self,
        payload: NotificationPayload,
        channels: Optional[list[NotificationChannel]] = None,
    ) -> dict[NotificationChannel, bool]:
        """
        Send notification to all (or specified) channels.
        
        Args:
            payload: Notification payload
            channels: Specific channels to use (None = all)
            
        Returns:
            Dict mapping channel to success status
        """
        results: dict[NotificationChannel, bool] = {}
        
        providers = self._providers
        if channels:
            providers = [p for p in providers if p.channel in channels]
        
        if not providers:
            logger.warning("No notification providers configured")
            return results
        
        # Send to all providers concurrently
        tasks = []
        for provider in providers:
            tasks.append(self._send_with_provider(provider, payload))
        
        outcomes = await asyncio.gather(*tasks, return_exceptions=True)
        
        for provider, outcome in zip(providers, outcomes):
            if isinstance(outcome, Exception):
                logger.error(
                    "Notification provider failed",
                    channel=provider.channel.value,
                    error=str(outcome),
                )
                results[provider.channel] = False
            else:
                results[provider.channel] = outcome
        
        return results
    
    async def _send_with_provider(
        self,
        provider: NotificationProvider,
        payload: NotificationPayload,
    ) -> bool:
        """Send with a single provider (for concurrent execution)."""
        try:
            return await provider.send(payload)
        except Exception as e:
            logger.error(
                "Provider send failed",
                channel=provider.channel.value,
                error=str(e),
            )
            return False
    
    async def send_budget_alert(
        self,
        budget_id: int,
        budget_name: str,
        threshold_percent: int,
        actual_percent: float,
        actual_amount: float,
        budget_amount: float,
        currency: str = "USD",
        channels: Optional[list[NotificationChannel]] = None,
    ) -> dict[NotificationChannel, bool]:
        """
        Send a budget alert notification.
        
        Args:
            budget_id: Budget ID
            budget_name: Budget name
            threshold_percent: Threshold that was exceeded
            actual_percent: Actual spend percentage
            actual_amount: Actual spend amount
            budget_amount: Total budget amount
            currency: Currency code
            channels: Specific channels (None = all)
            
        Returns:
            Dict mapping channel to success status
        """
        # Determine severity
        if actual_percent >= 100:
            severity = NotificationSeverity.CRITICAL
            emoji = "🚨"
        elif actual_percent >= 80:
            severity = NotificationSeverity.WARNING
            emoji = "⚠️"
        else:
            severity = NotificationSeverity.INFO
            emoji = "ℹ️"
        
        title = f"{emoji} Budget Alert: {budget_name}"
        message = (
            f"Budget '{budget_name}' has reached {actual_percent:.1f}% of its limit.\n\n"
            f"• **Threshold:** {threshold_percent}%\n"
            f"• **Current Spend:** {currency} {actual_amount:,.2f}\n"
            f"• **Budget Limit:** {currency} {budget_amount:,.2f}\n"
            f"• **Remaining:** {currency} {max(0, budget_amount - actual_amount):,.2f}"
        )
        
        payload = BudgetAlertPayload(
            title=title,
            message=message,
            severity=severity,
            budget_id=budget_id,
            budget_name=budget_name,
            threshold_percent=threshold_percent,
            actual_percent=actual_percent,
            actual_amount=actual_amount,
            budget_amount=budget_amount,
            currency=currency,
            metadata={
                "alert_type": "budget_threshold",
                "budget_id": budget_id,
            },
        )
        
        logger.info(
            "Sending budget alert notification",
            budget_id=budget_id,
            budget_name=budget_name,
            threshold=threshold_percent,
            actual=actual_percent,
        )
        
        return await self.send(payload, channels)
    
    async def send_system_alert(
        self,
        title: str,
        message: str,
        severity: NotificationSeverity = NotificationSeverity.INFO,
        metadata: Optional[dict[str, Any]] = None,
        channels: Optional[list[NotificationChannel]] = None,
    ) -> dict[NotificationChannel, bool]:
        """
        Send a system alert notification.
        
        Args:
            title: Alert title
            message: Alert message
            severity: Alert severity
            metadata: Additional metadata
            channels: Specific channels (None = all)
            
        Returns:
            Dict mapping channel to success status
        """
        payload = NotificationPayload(
            title=title,
            message=message,
            severity=severity,
            metadata=metadata or {},
        )
        
        return await self.send(payload, channels)


# Singleton instance
_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create singleton notification service instance."""
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service
