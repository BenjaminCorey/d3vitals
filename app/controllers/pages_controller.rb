class PagesController < ApplicationController
  respond_to :html, :json

  def index
    @pages = Page.all
    respond_with @pages
  end
  def show
    @page = Page.find_by_permalink! params[:id]
  end

end
