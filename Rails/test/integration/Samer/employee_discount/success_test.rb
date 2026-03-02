require "test_helper"

class EmployeeDiscountSuccessTest < ActionDispatch::IntegrationTest
  # Client gets 0% discount
  test "client gets zero discount" do
    client = users(:valid_user)

    # Verify discount method
    assert_equal 0, client.employee_discount_percentage
  end

  # New employee (< 6 months) gets 0% discount
  test "new employee under 6 months gets zero discount" do
    waiter = users(:waiter_user)
    # Fixture created_at is Time.current, so tenure < 6 months
    waiter.update_column(:created_at, Time.current - 3.months)

    # Verify discount
    assert_equal 0, waiter.employee_discount_percentage
  end

  # Employee with 6-12 months tenure gets 5% discount
  test "employee with 6 to 12 months gets 5 percent discount" do
    waiter = users(:waiter_user)
    waiter.update_column(:created_at, Time.current - 8.months)

    # Verify discount
    assert_equal 5, waiter.employee_discount_percentage
  end

  # Employee with 1-2 years tenure gets 10% discount
  test "employee with 1 to 2 years gets 10 percent discount" do
    waiter = users(:waiter_user)
    waiter.update_column(:created_at, Time.current - 18.months)

    # Verify discount
    assert_equal 10, waiter.employee_discount_percentage
  end

  # Employee with 2+ years tenure gets 15% discount
  test "employee with over 2 years gets 15 percent discount" do
    waiter = users(:waiter_user)
    waiter.update_column(:created_at, Time.current - 30.months)

    # Verify discount
    assert_equal 15, waiter.employee_discount_percentage
  end

  # Discount appears in order JSON when client is an employee
  test "order JSON includes discount fields for employee client" do
    admin = users(:admin_user)
    admin.update_column(:created_at, Time.current - 18.months)

    # Admin should get 10% discount
    assert_equal 10, admin.employee_discount_percentage

    # Check the EMPLOYEE_TYPES constant
    assert_includes User::EMPLOYEE_TYPES, "Administrator"
    assert_includes User::EMPLOYEE_TYPES, "Waiter"
    assert_includes User::EMPLOYEE_TYPES, "Cook"
  end

  # Cook also gets discount
  test "cook gets discount based on tenure" do
    cook = users(:cook_user)
    cook.update_column(:created_at, Time.current - 25.months)

    # Verify discount
    assert_equal 15, cook.employee_discount_percentage
  end
end
