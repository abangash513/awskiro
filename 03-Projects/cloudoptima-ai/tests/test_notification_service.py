"""Unit tests for notification service."""

import pytest
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.notification_service import (
    BudgetAlertPayload,
    NotificationChannel,
    NotificationPayload,
    NotificationService,
    NotificationSeverity,
    SlackProvider,
    TeamsProvider,
    WebhookProvider,
    get_notification_service,
)


class TestNotificationPayload:
    """Tests for notification payload dataclasses."""

    def test_notification_payload_to_dict(self):
        """Should convert payload to dictionary."""
        payload = NotificationPayload(
            title="Test Alert",
            message="This is a test",
            severity=NotificationSeverity.WARNING,
            metadata={"key": "value"},
        )
        
        result = payload.to_dict()
        
        assert result["title"] == "Test Alert"
        assert result["message"] == "This is a test"
        assert result["severity"] == "warning"
        assert result["source"] == "cloudoptima"
        assert result["metadata"] == {"key": "value"}
        assert "timestamp" in result

    def test_budget_alert_payload_to_dict(self):
        """Should include budget details in dictionary."""
        payload = BudgetAlertPayload(
            title="Budget Alert",
            message="Budget exceeded",
            severity=NotificationSeverity.CRITICAL,
            budget_id=123,
            budget_name="Production",
            threshold_percent=80,
            actual_percent=95.5,
            actual_amount=9550.00,
            budget_amount=10000.00,
        )
        
        result = payload.to_dict()
        
        assert result["title"] == "Budget Alert"
        assert "budget" in result
        assert result["budget"]["id"] == 123
        assert result["budget"]["name"] == "Production"
        assert result["budget"]["threshold_percent"] == 80
        assert result["budget"]["actual_percent"] == 95.5


class TestWebhookProvider:
    """Tests for webhook notification provider."""

    def test_is_configured_with_url(self):
        """Should be configured when URL is provided."""
        provider = WebhookProvider(webhook_url="https://example.com/webhook")
        
        assert provider.is_configured() is True

    def test_is_not_configured_without_url(self):
        """Should not be configured when URL is missing."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            mock_settings.return_value = settings
            
            provider = WebhookProvider()
            
            assert provider.is_configured() is False

    @pytest.mark.asyncio
    async def test_send_success(self):
        """Should send notification successfully."""
        provider = WebhookProvider(webhook_url="https://example.com/webhook")
        payload = NotificationPayload(
            title="Test",
            message="Test message",
            severity=NotificationSeverity.INFO,
        )
        
        with patch("httpx.AsyncClient") as mock_client:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_client.return_value.__aenter__.return_value.post = AsyncMock(
                return_value=mock_response
            )
            
            result = await provider.send(payload)
            
            assert result is True

    @pytest.mark.asyncio
    async def test_send_failure(self):
        """Should return False on send failure."""
        provider = WebhookProvider(webhook_url="https://example.com/webhook")
        payload = NotificationPayload(
            title="Test",
            message="Test message",
            severity=NotificationSeverity.INFO,
        )
        
        with patch("httpx.AsyncClient") as mock_client:
            mock_response = MagicMock()
            mock_response.status_code = 500
            mock_response.text = "Internal server error"
            mock_client.return_value.__aenter__.return_value.post = AsyncMock(
                return_value=mock_response
            )
            
            result = await provider.send(payload)
            
            assert result is False

    @pytest.mark.asyncio
    async def test_send_skips_when_not_configured(self):
        """Should skip and return False when not configured."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            mock_settings.return_value = settings
            
            provider = WebhookProvider()
            payload = NotificationPayload(
                title="Test",
                message="Test",
                severity=NotificationSeverity.INFO,
            )
            
            result = await provider.send(payload)
            
            assert result is False


class TestSlackProvider:
    """Tests for Slack notification provider."""

    def test_formats_payload_correctly(self):
        """Should format payload as Slack blocks."""
        provider = SlackProvider(webhook_url="https://hooks.slack.com/test")
        payload = NotificationPayload(
            title="Test Alert",
            message="This is a test",
            severity=NotificationSeverity.WARNING,
        )
        
        result = provider._format_payload(payload)
        
        assert "attachments" in result
        assert len(result["attachments"]) == 1
        assert result["attachments"][0]["color"] == "#ff9800"  # Warning color
        assert "blocks" in result["attachments"][0]

    def test_formats_budget_alert_with_fields(self):
        """Should include budget fields for budget alerts."""
        provider = SlackProvider(webhook_url="https://hooks.slack.com/test")
        payload = BudgetAlertPayload(
            title="Budget Alert",
            message="Budget exceeded",
            severity=NotificationSeverity.CRITICAL,
            budget_name="Production",
            threshold_percent=80,
            actual_percent=95.5,
            actual_amount=9550.00,
            budget_amount=10000.00,
        )
        
        result = provider._format_payload(payload)
        
        # Should have section with fields
        blocks = result["attachments"][0]["blocks"]
        field_block = [b for b in blocks if b.get("type") == "section" and "fields" in b]
        assert len(field_block) == 1

    @pytest.mark.asyncio
    async def test_send_success(self):
        """Should return True on successful send."""
        provider = SlackProvider(webhook_url="https://hooks.slack.com/test")
        payload = NotificationPayload(
            title="Test",
            message="Test",
            severity=NotificationSeverity.INFO,
        )
        
        with patch("httpx.AsyncClient") as mock_client:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.text = "ok"
            mock_client.return_value.__aenter__.return_value.post = AsyncMock(
                return_value=mock_response
            )
            
            result = await provider.send(payload)
            
            assert result is True


class TestTeamsProvider:
    """Tests for Microsoft Teams notification provider."""

    def test_formats_payload_as_message_card(self):
        """Should format payload as Teams MessageCard."""
        provider = TeamsProvider(webhook_url="https://outlook.office.com/webhook/test")
        payload = NotificationPayload(
            title="Test Alert",
            message="This is a test",
            severity=NotificationSeverity.CRITICAL,
        )
        
        result = provider._format_payload(payload)
        
        assert result["@type"] == "MessageCard"
        assert result["themeColor"] == "FF0000"  # Critical = red
        assert "sections" in result
        assert len(result["sections"]) == 1


class TestNotificationService:
    """Tests for the notification service."""

    def test_add_provider(self):
        """Should add configured provider."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service = NotificationService()
            provider = WebhookProvider(webhook_url="https://example.com/webhook")
            
            service.add_provider(provider)
            
            assert NotificationChannel.WEBHOOK in service.configured_channels

    def test_remove_provider(self):
        """Should remove providers for a channel."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service = NotificationService()
            service.add_provider(WebhookProvider(webhook_url="https://example.com"))
            
            service.remove_provider(NotificationChannel.WEBHOOK)
            
            assert NotificationChannel.WEBHOOK not in service.configured_channels

    @pytest.mark.asyncio
    async def test_send_to_all_channels(self):
        """Should send to all configured channels."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service = NotificationService()
            
            # Add mock providers
            mock_webhook = MagicMock(spec=WebhookProvider)
            mock_webhook.channel = NotificationChannel.WEBHOOK
            mock_webhook.is_configured.return_value = True
            mock_webhook.send = AsyncMock(return_value=True)
            
            mock_slack = MagicMock(spec=SlackProvider)
            mock_slack.channel = NotificationChannel.SLACK
            mock_slack.is_configured.return_value = True
            mock_slack.send = AsyncMock(return_value=True)
            
            service._providers = [mock_webhook, mock_slack]
            
            payload = NotificationPayload(
                title="Test",
                message="Test",
                severity=NotificationSeverity.INFO,
            )
            
            results = await service.send(payload)
            
            assert results[NotificationChannel.WEBHOOK] is True
            assert results[NotificationChannel.SLACK] is True

    @pytest.mark.asyncio
    async def test_send_to_specific_channels(self):
        """Should send only to specified channels."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service = NotificationService()
            
            # Add mock providers
            mock_webhook = MagicMock(spec=WebhookProvider)
            mock_webhook.channel = NotificationChannel.WEBHOOK
            mock_webhook.is_configured.return_value = True
            mock_webhook.send = AsyncMock(return_value=True)
            
            mock_slack = MagicMock(spec=SlackProvider)
            mock_slack.channel = NotificationChannel.SLACK
            mock_slack.is_configured.return_value = True
            mock_slack.send = AsyncMock(return_value=True)
            
            service._providers = [mock_webhook, mock_slack]
            
            payload = NotificationPayload(
                title="Test",
                message="Test",
                severity=NotificationSeverity.INFO,
            )
            
            # Send only to webhook
            results = await service.send(payload, channels=[NotificationChannel.WEBHOOK])
            
            assert NotificationChannel.WEBHOOK in results
            assert NotificationChannel.SLACK not in results
            mock_slack.send.assert_not_called()

    @pytest.mark.asyncio
    async def test_send_budget_alert_critical(self):
        """Should determine correct severity for critical alerts."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service = NotificationService()
            
            mock_provider = MagicMock(spec=WebhookProvider)
            mock_provider.channel = NotificationChannel.WEBHOOK
            mock_provider.is_configured.return_value = True
            mock_provider.send = AsyncMock(return_value=True)
            service._providers = [mock_provider]
            
            await service.send_budget_alert(
                budget_id=1,
                budget_name="Test Budget",
                threshold_percent=100,
                actual_percent=105.0,  # Over 100% = critical
                actual_amount=10500,
                budget_amount=10000,
            )
            
            # Verify the payload was critical severity
            call_args = mock_provider.send.call_args
            payload = call_args[0][0]
            assert payload.severity == NotificationSeverity.CRITICAL

    @pytest.mark.asyncio
    async def test_send_budget_alert_warning(self):
        """Should determine correct severity for warning alerts."""
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service = NotificationService()
            
            mock_provider = MagicMock(spec=WebhookProvider)
            mock_provider.channel = NotificationChannel.WEBHOOK
            mock_provider.is_configured.return_value = True
            mock_provider.send = AsyncMock(return_value=True)
            service._providers = [mock_provider]
            
            await service.send_budget_alert(
                budget_id=1,
                budget_name="Test Budget",
                threshold_percent=80,
                actual_percent=85.0,  # 80-99% = warning
                actual_amount=8500,
                budget_amount=10000,
            )
            
            call_args = mock_provider.send.call_args
            payload = call_args[0][0]
            assert payload.severity == NotificationSeverity.WARNING


class TestNotificationServiceSingleton:
    """Tests for notification service singleton."""

    def test_get_notification_service_returns_singleton(self):
        """Should return the same instance."""
        import app.services.notification_service as module
        module._notification_service = None
        
        with patch("app.services.notification_service.get_settings") as mock_settings:
            settings = MagicMock()
            settings.notification_webhook_url = None
            settings.slack_webhook_url = None
            settings.teams_webhook_url = None
            mock_settings.return_value = settings
            
            service1 = get_notification_service()
            service2 = get_notification_service()
            
            assert service1 is service2
