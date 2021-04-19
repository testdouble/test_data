class BoopsController < ApplicationController
  def index
    @boops = Boop.all
  end

  def create
    Boop.create!
    redirect_to boops_path
  end
end
