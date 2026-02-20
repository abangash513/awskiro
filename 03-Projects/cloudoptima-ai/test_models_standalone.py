"""Standalone test to verify models can be imported and tables created without foreign key errors."""

import sys
from pathlib import Path

# Add app directory to path
sys.path.insert(0, str(Path(__file__).parent))

def test_model_imports():
    """Test that models can be imported without errors."""
    print("Testing model imports...")
    try:
        from app.models import CostRecord, CostSummary, Budget, BudgetAlert, Recommendation
        print("✓ All models imported successfully")
        return True
    except Exception as e:
        print(f"✗ Model import failed: {e}")
        return False

def test_model_structure():
    """Test that models have correct structure."""
    print("\nTesting model structure...")
    try:
        from app.models.recommendation import Recommendation
        from app.models.budget import Budget
        from app.models.cost import CostRecord
        
        # Check Recommendation doesn't have foreign keys
        rec_columns = [col.name for col in Recommendation.__table__.columns]
        print(f"  Recommendation columns: {', '.join(rec_columns[:5])}...")
        
        # Check for problematic foreign keys
        rec_fks = [fk.parent.name for fk in Recommendation.__table__.foreign_keys]
        if rec_fks:
            print(f"✗ Recommendation has foreign keys: {rec_fks}")
            return False
        print("✓ Recommendation has no foreign keys")
        
        # Check Budget
        budget_fks = [fk.parent.name for fk in Budget.__table__.foreign_keys]
        if budget_fks:
            print(f"✗ Budget has foreign keys: {budget_fks}")
            return False
        print("✓ Budget has no foreign keys")
        
        # Check CostRecord
        cost_fks = [fk.parent.name for fk in CostRecord.__table__.foreign_keys]
        if cost_fks:
            print(f"✗ CostRecord has foreign keys: {cost_fks}")
            return False
        print("✓ CostRecord has no foreign keys")
        
        return True
    except Exception as e:
        print(f"✗ Model structure test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_table_creation():
    """Test that tables can be created in memory."""
    print("\nTesting table creation...")
    try:
        from sqlalchemy import create_engine
        from app.core.database import Base
        from app.models import CostRecord, CostSummary, Budget, BudgetAlert, Recommendation
        
        # Create in-memory SQLite database
        engine = create_engine("sqlite:///:memory:", echo=False)
        
        # Try to create all tables
        Base.metadata.create_all(engine)
        
        # Check tables were created
        tables = Base.metadata.tables.keys()
        print(f"✓ Created tables: {', '.join(tables)}")
        
        expected_tables = {'cost_records', 'cost_summaries', 'budgets', 'budget_alerts', 'recommendations'}
        if not expected_tables.issubset(tables):
            missing = expected_tables - set(tables)
            print(f"✗ Missing tables: {missing}")
            return False
        
        print("✓ All expected tables created successfully")
        return True
    except Exception as e:
        print(f"✗ Table creation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("CloudOptima AI - Model Validation Test")
    print("=" * 60)
    
    results = []
    results.append(("Import Test", test_model_imports()))
    results.append(("Structure Test", test_model_structure()))
    results.append(("Table Creation Test", test_table_creation()))
    
    print("\n" + "=" * 60)
    print("Test Results:")
    print("=" * 60)
    
    all_passed = True
    for test_name, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"{test_name}: {status}")
        if not passed:
            all_passed = False
    
    print("=" * 60)
    if all_passed:
        print("✓ All tests passed! Models are ready for deployment.")
        sys.exit(0)
    else:
        print("✗ Some tests failed. Fix issues before deploying.")
        sys.exit(1)
