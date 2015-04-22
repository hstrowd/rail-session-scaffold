class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    if !params[:id]
      render status: :bad_request
      return
    end

    # TODO: Look into connection pooling for this.
    redisStore = Redis::Store.new(Rails.application.config.redis_connection_params)
    requestedSession = redisStore.get(params[:id])

    if !requestedSession
      render status: :bad_request, json: {
        error: "No session found with ID '#{params[:id]}'"
      }
      return
    end

    # NOTE: This is a hack that should never be done in a production app,
    #   but allows us to reuse another active session and operate on it
    #   via the frontend controls exposed. These operations should only be
    #   performed programatically in a production app.
    session.id = params[:id]
    session.replace(requestedSession)
  end

  def update
    if !params[:key]
      render status: :bad_request, json: { error: 'Missing key parameter.'}
      return
    end

    session[params[:key]] = params[:value]
  end

  def destroy
    reset_session
  end
end
