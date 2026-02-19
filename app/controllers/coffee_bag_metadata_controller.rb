class CoffeeBagMetadataController < ApplicationController
  include Metadatable

  before_action :require_authentication

  def create
    create_metadata_field(:coffee_bag)
  end

  def destroy
    destroy_metadata_field(:coffee_bag)
  end
end
