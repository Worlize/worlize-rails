require 'test_helper'

class MarketplaceLicensesControllerTest < ActionController::TestCase
  setup do
    @marketplace_license = marketplace_licenses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:marketplace_licenses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create marketplace_license" do
    assert_difference('MarketplaceLicense.count') do
      post :create, :marketplace_license => @marketplace_license.attributes
    end

    assert_redirected_to marketplace_license_path(assigns(:marketplace_license))
  end

  test "should show marketplace_license" do
    get :show, :id => @marketplace_license.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @marketplace_license.to_param
    assert_response :success
  end

  test "should update marketplace_license" do
    put :update, :id => @marketplace_license.to_param, :marketplace_license => @marketplace_license.attributes
    assert_redirected_to marketplace_license_path(assigns(:marketplace_license))
  end

  test "should destroy marketplace_license" do
    assert_difference('MarketplaceLicense.count', -1) do
      delete :destroy, :id => @marketplace_license.to_param
    end

    assert_redirected_to marketplace_licenses_path
  end
end
