require 'test_helper'

class ParanoidBaseTest < ActiveSupport::TestCase
  def assert_empty(collection)
    assert(collection.respond_to?(:empty?) && collection.empty?)
  end
  
  def setup
    setup_db

    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      ParanoidTime.create! :name => name
      ParanoidBoolean.create! :name => name
    end

    ParanoidString.create! :name => "strings can be paranoid"
    NotParanoid.create! :name => "no paranoid goals"
    ParanoidWithCallback.create! :name => "paranoid with callbacks"

    ParanoidObserver.instance.reset
  end

  def teardown
    teardown_db
  end
end

class ParanoidTest < ParanoidBaseTest
  def test_fake_removal
    assert_equal 3, ParanoidTime.not_deleted.count
    assert_equal 3, ParanoidBoolean.not_deleted.count
    assert_equal 1, ParanoidString.not_deleted.count

    ParanoidTime.not_deleted.first.destroy
    ParanoidBoolean.delete_all("name = 'paranoid' OR name = 'really paranoid'")
    ParanoidString.not_deleted.first.destroy
    assert_equal 2, ParanoidTime.not_deleted.count
    assert_equal 1, ParanoidBoolean.not_deleted.count
    assert_equal 0, ParanoidString.not_deleted.count
    assert_equal 1, ParanoidTime.only_deleted.count 
    assert_equal 2, ParanoidBoolean.only_deleted.count
    assert_equal 1, ParanoidString.only_deleted.count
    assert_equal 3, ParanoidTime.with_deleted.count
    assert_equal 3, ParanoidBoolean.with_deleted.count
    assert_equal 1, ParanoidString.with_deleted.count
  end

  def test_real_removal
    ParanoidTime.not_deleted.first.destroy!
    ParanoidBoolean.delete_all!("name = 'extremely paranoid' OR name = 'really paranoid'")
    ParanoidString.not_deleted.first.destroy!
    assert_equal 2, ParanoidTime.not_deleted.count
    assert_equal 1, ParanoidBoolean.not_deleted.count
    assert_equal 0, ParanoidString.not_deleted.count
    assert_equal 2, ParanoidTime.with_deleted.count
    assert_equal 1, ParanoidBoolean.with_deleted.count
    assert_equal 0, ParanoidString.with_deleted.count
    assert_equal 0, ParanoidTime.only_deleted.count
    assert_equal 0, ParanoidBoolean.only_deleted.count
    assert_equal 0, ParanoidString.only_deleted.count

    ParanoidTime.not_deleted.first.destroy
    ParanoidTime.only_deleted.first.destroy
    assert_equal 0, ParanoidTime.only_deleted.count

    ParanoidTime.delete_all!
    assert_empty ParanoidTime.not_deleted.all
    assert_empty ParanoidTime.with_deleted.all
  end

  def test_paranoid_scope
    assert_raise(NoMethodError) { NotParanoid.delete_all! }
    assert_raise(NoMethodError) { NotParanoid.first.destroy! }
    assert_raise(NoMethodError) { NotParanoid.with_deleted }
    assert_raise(NoMethodError) { NotParanoid.only_deleted }    
  end

  def test_recovery
    assert_equal 3, ParanoidBoolean.not_deleted.count
    ParanoidBoolean.not_deleted.first.destroy
    assert_equal 2, ParanoidBoolean.not_deleted.count
    ParanoidBoolean.only_deleted.first.recover
    assert_equal 3, ParanoidBoolean.not_deleted.count

    assert_equal 1, ParanoidString.not_deleted.count
    ParanoidString.not_deleted.first.destroy
    assert_equal 0, ParanoidString.not_deleted.count
    ParanoidString.with_deleted.first.recover
    assert_equal 1, ParanoidString.not_deleted.count
  end

  def setup_recursive_recovery_tests
    @paranoid_time_object = ParanoidTime.not_deleted.first

    @paranoid_boolean_count = ParanoidBoolean.not_deleted.count

    assert_equal 0, ParanoidHasManyDependant.not_deleted.count
    assert_equal 0, ParanoidBelongsDependant.not_deleted.count

    (1..3).each do |i|
      has_many_object = @paranoid_time_object.paranoid_has_many_dependants.create(:name => "has_many_#{i}")
      has_many_object.create_paranoid_belongs_dependant(:name => "belongs_to_#{i}")
      has_many_object.save

      paranoid_boolean = @paranoid_time_object.paranoid_booleans.create(:name => "boolean_#{i}")
      paranoid_boolean.create_paranoid_has_one_dependant(:name => "has_one_#{i}")
      paranoid_boolean.save

      @paranoid_time_object.not_paranoids.create(:name => "not_paranoid_a#{i}")

    end

    @paranoid_time_object.create_not_paranoid(:name => "not_paranoid_belongs_to")

    @paranoid_time_object.create_has_one_not_paranoid(:name => "has_one_not_paranoid")

    assert_equal 3, ParanoidTime.not_deleted.count
    assert_equal 3, ParanoidHasManyDependant.not_deleted.count
    assert_equal 3, ParanoidBelongsDependant.not_deleted.count
    assert_equal 3, ParanoidHasOneDependant.not_deleted.count
    assert_equal 5, NotParanoid.count
    assert_equal 1, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.not_deleted.count

    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    assert_equal 2, ParanoidTime.not_deleted.count
    assert_equal 0, ParanoidHasManyDependant.not_deleted.count
    assert_equal 0, ParanoidBelongsDependant.not_deleted.count
    assert_equal 0, ParanoidHasOneDependant.not_deleted.count

    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.not_deleted.count
  end

  def test_recursive_recovery
    setup_recursive_recovery_tests

    @paranoid_time_object.recover(:recursive => true)

    assert_equal 3, ParanoidTime.not_deleted.count
    assert_equal 3, ParanoidHasManyDependant.not_deleted.count
    assert_equal 3, ParanoidBelongsDependant.not_deleted.count
    assert_equal 3, ParanoidHasOneDependant.not_deleted.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.not_deleted.count
  end

  def test_non_recursive_recovery
    setup_recursive_recovery_tests

    @paranoid_time_object.recover(:recursive => false)

    assert_equal 3, ParanoidTime.not_deleted.count
    assert_equal 0, ParanoidHasManyDependant.not_deleted.count
    assert_equal 0, ParanoidBelongsDependant.not_deleted.count
    assert_equal 0, ParanoidHasOneDependant.not_deleted.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.not_deleted.count
  end

  def test_deleted?
    ParanoidTime.not_deleted.first.destroy
    assert ParanoidTime.with_deleted.first.deleted?

    ParanoidString.not_deleted.first.destroy
    assert ParanoidString.with_deleted.first.deleted?
  end
  
  def test_paranoid_destroy_callbacks    
    @paranoid_with_callback = ParanoidWithCallback.not_deleted.first
    ParanoidWithCallback.transaction do
      @paranoid_with_callback.destroy
    end
    
    assert @paranoid_with_callback.called_before_destroy
    assert @paranoid_with_callback.called_after_destroy
    assert @paranoid_with_callback.called_after_commit_on_destroy
  end
  
  def test_hard_destroy_callbacks
    @paranoid_with_callback = ParanoidWithCallback.not_deleted.first
    
    ParanoidWithCallback.transaction do
      @paranoid_with_callback.destroy!
    end
    
    assert @paranoid_with_callback.called_before_destroy
    assert @paranoid_with_callback.called_after_destroy
    assert @paranoid_with_callback.called_after_commit_on_destroy
  end

  def test_recovery_callbacks
    @paranoid_with_callback = ParanoidWithCallback.not_deleted.first

    ParanoidWithCallback.transaction do
      @paranoid_with_callback.destroy

      assert_nil @paranoid_with_callback.called_before_recover
      assert_nil @paranoid_with_callback.called_after_recover

      @paranoid_with_callback.recover
    end

      assert @paranoid_with_callback.called_before_recover
      assert @paranoid_with_callback.called_after_recover    
  end
end

class ValidatesUniquenessTest < ParanoidBaseTest
  def test_should_include_deleted_by_default
    ParanoidTime.new(:name => 'paranoid').tap do |record|
      assert !record.valid?
      ParanoidTime.not_deleted.first.destroy
      assert !record.valid?
      ParanoidTime.only_deleted.first.destroy!
      assert record.valid?
    end
  end

  def test_should_validate_without_deleted
    ParanoidBoolean.new(:name => 'paranoid').tap do |record|
      ParanoidBoolean.not_deleted.first.destroy
      assert record.valid?
      ParanoidBoolean.only_deleted.first.destroy!
      assert record.valid?
    end
  end
end

class AssociationsTest < ParanoidBaseTest  
  def test_removal_with_associations
    # This test shows that the current implementation doesn't handle
    # assciation deletion correctly (when hard deleting via parent-object)
    paranoid_company_1 = ParanoidDestroyCompany.create! :name => "ParanoidDestroyCompany #1"
    paranoid_company_2 = ParanoidDeleteCompany.create! :name => "ParanoidDestroyCompany #1"
    paranoid_company_1.paranoid_products.create! :name => "ParanoidProduct #1"
    paranoid_company_2.paranoid_products.create! :name => "ParanoidProduct #2"
    
    assert_equal 1, ParanoidDestroyCompany.not_deleted.count
    assert_equal 1, ParanoidDeleteCompany.not_deleted.count
    assert_equal 2, ParanoidProduct.not_deleted.count

    ParanoidDestroyCompany.not_deleted.first.destroy
    assert_equal 0, ParanoidDestroyCompany.not_deleted.count
    assert_equal 1, ParanoidProduct.not_deleted.count
    assert_equal 1, ParanoidDestroyCompany.with_deleted.count
    assert_equal 2, ParanoidProduct.with_deleted.count
  
    ParanoidDestroyCompany.with_deleted.first.destroy!
    assert_equal 0, ParanoidDestroyCompany.not_deleted.count
    assert_equal 1, ParanoidProduct.not_deleted.count
    assert_equal 0, ParanoidDestroyCompany.with_deleted.count
    assert_equal 1, ParanoidProduct.with_deleted.count
    
    ParanoidDeleteCompany.with_deleted.first.destroy!
    assert_equal 0, ParanoidDeleteCompany.not_deleted.count
    assert_equal 0, ParanoidProduct.not_deleted.count
    assert_equal 0, ParanoidDeleteCompany.with_deleted.count
    assert_equal 0, ParanoidProduct.with_deleted.count
  end
end

class InheritanceTest < ParanoidBaseTest
  def test_destroy_dependents_with_inheritance
    has_many_inherited_super_paranoidz = HasManyInheritedSuperParanoidz.new
    has_many_inherited_super_paranoidz.save
    has_many_inherited_super_paranoidz.super_paranoidz.create
    assert_nothing_raised(NoMethodError) { has_many_inherited_super_paranoidz.destroy }
  end
  
  def test_class_instance_variables_are_inherited
    assert_nothing_raised(ActiveRecord::StatementInvalid) { InheritedParanoid.paranoid_column }
  end
end

class ParanoidObserverTest < ParanoidBaseTest

  def test_called_observer_methods
    @subject = ParanoidWithCallback.new
    @subject.save

    assert_nil ParanoidObserver.instance.called_before_recover
    assert_nil ParanoidObserver.instance.called_after_recover
    
    ParanoidWithCallback.not_deleted.find(@subject.id).recover

    assert_equal @subject, ParanoidObserver.instance.called_before_recover
    assert_equal @subject, ParanoidObserver.instance.called_after_recover
  end
end
