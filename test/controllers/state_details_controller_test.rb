require 'test_helper'

class StateDetailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @state_detail = state_details(:one)
  end

  test "should get index" do
    get state_details_url
    assert_response :success
  end

  test "should get new" do
    get new_state_detail_url
    assert_response :success
  end

  test "should create state_detail" do
    assert_difference('StateDetail.count') do
      post state_details_url, params: { state_detail: {  } }
    end

    assert_redirected_to state_detail_url(StateDetail.last)
  end

  test "should show state_detail" do
    get state_detail_url(@state_detail)
    assert_response :success
  end

  test "should get edit" do
    get edit_state_detail_url(@state_detail)
    assert_response :success
  end

  test "should update state_detail" do
    patch state_detail_url(@state_detail), params: { state_detail: {  } }
    assert_redirected_to state_detail_url(@state_detail)
  end

  test "should destroy state_detail" do
    assert_difference('StateDetail.count', -1) do
      delete state_detail_url(@state_detail)
    end

    assert_redirected_to state_details_url
  end
end
