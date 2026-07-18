class OfflinesController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    render layout: false
  end
end
