require "test_helper"

module Airtable
  class BaseTest < ActiveSupport::TestCase
    setup do
      @identity = create(:identity, provider: "airtable")
    end

    test "it sets up a base the user can create in" do
      stub_request(:get, "https://api.airtable.com/v0/meta/bases")
        .to_return(status: 200, body: {bases: [{id: "appEdit", name: "Visualizer", permissionLevel: "edit"}, {id: "appCreate", name: "Coffee", permissionLevel: "create"}]}.to_json)
      stub_request(:get, "https://api.airtable.com/v0/bases/appCreate/webhooks")
        .to_return(status: 200, body: {webhooks: []}.to_json)
      stub_request(:post, "https://api.airtable.com/v0/bases/appCreate/webhooks")
        .to_return(status: 200, body: {id: "achNew"}.to_json)

      Airtable::Base.new(@identity.user)

      assert_equal "appCreate", @identity.reload.airtable_info.base_id
    end

    test "it disconnects airtable when no base can be created in" do
      stub_request(:get, "https://api.airtable.com/v0/meta/bases")
        .to_return(status: 200, body: {bases: [{id: "appEdit", name: "Visualizer", permissionLevel: "edit"}]}.to_json)

      assert_raises(Airtable::BaseError) { Airtable::Base.new(@identity.user) }
      assert_not Identity.exists?(@identity.id)
    end
  end
end
