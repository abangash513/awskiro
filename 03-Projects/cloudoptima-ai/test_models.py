#!/usr/bin/env python3
"""Test script to validate database models."""

import asyncio
import sys
from pathlib import Path

# Add app to path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.core.database import Base
from app.models import CostRecord, CostSummary, Budget, BudgetAlert, Recommendation


async def test_models():
    """Test that all models can be created without errors."""
    
    print("=" * 60)
    print("Testing CloudOptima AI Database Models")
    print("=" * 60)
    print()
    
    # Use in-memory SQLite for testing
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
    )
    
    try:
        print("✓ Database engine created")
        
        # Create all tables
        print("Creating tables...")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        print("✓ All tables created successfully")
        print()
        
        # List all tables
        print("Tables created:")
        for table_name in Base.metadata.tables.keys():
            table = Base.metadata.tables[table_name]
            columns = [col.name for col in table.columns]
            print(f"  • {table_name}")
            print(f"    Columns: {', '.join(columns[:5])}" + 
                  (f"... (+{len(columns)-5} more)" if len(columns) > 5 else ""))
        
        print()
        
        # Test creating a session
        async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        async with async_session() as session:
            print("✓ Database session created")
        
        print()
        print("=" * 60)
        print("✅ All tests passed! Models are valid.")
        print("=" * 60)
        
        return True
        
    except Exception as e:
        print()
        print("=" * 60)
        print("❌ Test failed!")
        print("=" * 60)
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        await engine.dispose()


async def test_model_relationships():
    """Test model relationships."""
    
    print()
    print("Testing model relationships...")
    
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
    )
    
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        
        async with async_session() as session:
            # Test Budget -> BudgetAlert relationship
            from datetime import datetime
            from decimal import Decimal
            
            budget = Budget(
                name="Test Budget",
                subscription_id="test-sub-123",
                amount=Decimal("1000.00"),
                start_date=datetime.now(),
            )
            session.add(budget)
            await session.flush()
            
            alert = BudgetAlert(
                budget_id=budget.id,
                threshold_percent=80,
                actual_percent=Decimal("85.50"),
                actual_amount=Decimal("855.00"),
                severity="warning",
                message="Budget threshold exceeded",
            )
            session.add(alert)
            await session.commit()
            
            print("✓ Budget and BudgetAlert relationship works")
            
            # Test CostRecord creation
            cost = CostRecord(
                subscription_id="test-sub-123",
                resource_group="test-rg",
                resource_name="test-vm",
                resource_type="Microsoft.Compute/virtualMachines",
                service_name="Virtual Machines",
                cost=Decimal("50.25"),
                usage_date=datetime.now(),
            )
            session.add(cost)
            await session.commit()
            
            print("✓ CostRecord creation works")
            
            # Test Recommendation creation
            rec = Recommendation(
                subscription_id="test-sub-123",
                title="Test Recommendation",
                description="This is a test",
                category="rightsizing",
                impact="high",
                estimated_monthly_savings=Decimal("100.00"),
                estimated_annual_savings=Decimal("1200.00"),
                valid_from=datetime.now(),
            )
            session.add(rec)
            await session.commit()
            
            print("✓ Recommendation creation works")
        
        print("✓ All relationship tests passed")
        return True
        
    except Exception as e:
        print(f"❌ Relationship test failed: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        await engine.dispose()


async def main():
    """Run all tests."""
    
    # Test 1: Model creation
    test1 = await test_models()
    
    if not test1:
        sys.exit(1)
    
    # Test 2: Relationships
    test2 = await test_model_relationships()
    
    if not test2:
        sys.exit(1)
    
    print()
    print("🎉 All tests passed! Models are ready to deploy.")
    print()


if __name__ == "__main__":
    asyncio.run(main())
