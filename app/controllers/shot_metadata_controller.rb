class ShotMetadataController < ApplicationController
  include Metadatable

  before_action :require_authentication
  before_action :check_premium!

  def create
    create_metadata_field(:shot)
  end

  def destroy
    destroy_metadata_field(:shot)
  end
end
