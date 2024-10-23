require "test_helper"

module Airtable
  class ShotsTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, :with_airtable)
      @identity = @user.identities.first
      @shot = create(:shot, :with_airtable, user: @user, airtable_id: "rec1")
    end

    test "it can delete a record" do
      stub = stub_request(:delete, "https://api.airtable.com/v0/#{@identity.airtable_info.base_id}/#{@identity.airtable_info.tables["Shots"]["id"]}/#{@shot.airtable_id}")
        .with(headers: {"Authorization" => "Bearer #{@identity.token}"})
        .to_return(status: 200, body: {deleted: true, id: @shot.airtable_id}.to_json, headers: {})
      delete = Airtable::Shots.new(@user).delete(@shot.airtable_id)
      assert_requested(stub)
      assert delete["deleted"]
      assert_equal @shot.airtable_id, delete["id"]
    end

    test "it can download new data for existing records from airtable" do
      stub_request(:get, "https://api.airtable.com/v0/#{@identity.airtable_info.base_id}/#{@identity.airtable_info.tables["Shots"]["id"]}?filterByFormula=DATETIME_DIFF%28NOW%28%29%2C+LAST_MODIFIED_TIME%28%29%2C+%27minutes%27%29+%3C+60")
        .to_return(File.new("test/files/airtable/download.txt"))

      assert_nil @shot.profile_title
      assert_nil @shot.barista
      assert_nil @shot.bean_brand
      assert_nil @shot.bean_type
      assert_nil @shot.bean_weight
      assert_nil @shot.espresso_enjoyment
      assert_empty(@shot.metadata)

      records = Airtable::Shots.new(@user).download
      assert_equal 4, records.count
      assert_equal 1, @user.shots.count

      @shot = Shot.find(@shot.id)
      assert_equal "TurboBloom M", @shot.profile_title
      assert_equal "Miha Rekar", @shot.barista
      assert_equal "Beansmith's", @shot.bean_brand
      assert_equal "Genji Challa", @shot.bean_type
      assert_equal "17.0", @shot.bean_weight
      assert_equal 80, @shot.espresso_enjoyment
      assert_equal({"Bean variety" => "Catuai", "Portafilter basket" => "Decent"}, @shot.metadata)
    end

    test "it uploads changes to airtable after shot save" do
      Shot.find(@shot.id).update(espresso_enjoyment: 80)
      assert_enqueued_with(job: AirtableUploadRecordJob, args: [@shot], queue: "default")

      stub = stub_request(:patch, "https://api.airtable.com/v0/#{@identity.airtable_info.base_id}/#{@identity.airtable_info.tables["Shots"]["id"]}/#{@shot.airtable_id}")
        .with(headers: {"Authorization" => "Bearer #{@identity.token}", "Content-Type" => "application/json"})
        .to_return(status: 200, body: {id: @shot.airtable_id}.to_json, headers: {})

      perform_enqueued_jobs
      assert_requested(stub)
    end

    test "it uploads a new record to airtable" do
      shot_id = "e5b3a587-809a-444a-bb27-e2f5bdbeacbe"
      sync = Airtable::Shots.new(@user)
      shot = @user.shots.create!(id: shot_id, espresso_enjoyment: 80, start_time: "2023-05-05T15:50:44.093Z", information: ShotInformation.new(timeframe: ["1"], data: {weight: []}), sha: "123")
      assert_enqueued_with(job: AirtableUploadRecordJob, args: [shot], queue: "default")

      stub = stub_request(:patch, "https://api.airtable.com/v0/#{@identity.airtable_info.base_id}/#{@identity.airtable_info.tables["Shots"]["id"]}")
        .with(
          headers: {"Authorization" => "Bearer #{@identity.token}", "Content-Type" => "application/json"},
          body: {performUpsert: {fieldsToMergeOn: ["ID"]}, records: [sync.__send__(:prepare_record, shot)]}
        )
        .to_return(File.new("test/files/airtable/upload.txt"))
      perform_enqueued_jobs
      assert_requested(stub)
      shot.reload
      assert_equal "receheiFe9F63F8EG", shot.airtable_id
    end

    test "it deletes in airtable after destroy" do
      perform_enqueued_jobs

      @shot.destroy
      assert_enqueued_with(job: AirtableDeleteRecordJob, args: [Airtable::Shots, @user, "rec1"], queue: "default")

      stub = stub_request(:delete, "https://api.airtable.com/v0/#{@identity.airtable_info.base_id}/#{@identity.airtable_info.tables["Shots"]["id"]}/#{@shot.airtable_id}")
        .with(headers: {"Authorization" => "Bearer #{@identity.token}", "Content-Type" => "application/json"})
        .to_return(status: 200, body: {id: @shot.airtable_id}.to_json, headers: {})

      perform_enqueued_jobs
      assert_requested(stub)
    end

    test "it raises error when no identity is present" do
      user = create(:user)
      error = assert_raise(StandardError) { Airtable::Shots.new(user) }
      assert_equal "Airtable identity not found for User##{user.id}", error.message
    end
  end
end
