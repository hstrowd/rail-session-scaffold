class SessionsController < ApplicationController
  def create
    if !params[:id]
      render status: :bad_request
      return
    end

    # TODO: Should this connection be persisted and shared across processes?
    redisStore = ActiveSupport::Cache::RedisStore.new(Rails.application.config.redis_connection_params)
    requestedSession = redisStore.read(params[:id])

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
