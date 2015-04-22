class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    if !params[:id]
      render status: :bad_request
    end

    render status: :not_implemented, json: {
      error: 'Direct loading of sessions is not supported for the cookie session store.'
    }
  end

  def update
    if !params[:key]
      render status: :bad_request, json: { error: 'Missing key parameter.'}
    end

    session[params[:key]] = params[:value]
  end

  def destroy
    reset_session
  end
end
