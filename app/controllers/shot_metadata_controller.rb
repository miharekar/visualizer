class ShotMetadataController < ApplicationController
  include Metadatable

  before_action :require_authentication

  def create
    create_metadata_field(:shot)
  end

  def destroy
    destroy_metadata_field(:shot)
  end
end
