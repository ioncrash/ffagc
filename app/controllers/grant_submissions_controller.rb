require 'grant_contract'

class GrantSubmissionsController < ApplicationController

  before_filter :initialize_grant_submission

  def initialize_grant_submission
    @grant_submission = GrantSubmission.new
  end

  def grant_submission_params
    params.require(:grant_submission).permit(:name, :proposal, :grant_id, :requested_funding_dollars)
  end

  def create
    if !current_artist
      return
    end

    @grant_submission = GrantSubmission.new(grant_submission_params)

    @grant_submission.artist_id = current_artist.id

    if @grant_submission.save
      render "success"
    else
      render "failure"
    end
  end
  
  def grant_update_params
    params.require(:grant_submission).permit(:id, :name, :grant_id, :requested_funding_dollars, :proposal)
  end

  def update
    @grant_submission = GrantSubmission.find(params[:id])
    
    if @grant_submission.artist_id != current_artist.id
      logger.warn "grant modification artist id mismatch: #{@grant_submission.artist_id} != #{current_artist.id}"
      if admin_logged_in
        logger.warn "OVERRIDE because admin logged in"
      else
        render "failure"
        return
      end
    end
    
    @grant_submission.name = grant_update_params[:name]
    if grant_update_params[:proposal] != ""
      @grant_submission.proposal = grant_update_params[:proposal]
    end
    @grant_submission.grant_id = grant_update_params[:grant_id]
    @grant_submission.requested_funding_dollars = grant_update_params[:requested_funding_dollars]

    if @grant_submission.save
      if admin_logged_in? 
        render "success_admin"
      else
        render "success_modify"
      end
    else
      if admin_logged_in?
        render "failure_admin"
      else
        render "failure_modify"
      end
    end
  end

  def index
  end
  
  def modify
    begin
      @grant_submission = GrantSubmission.find(params.permit(:id)[:id])
      if @grant_submission.artist_id != current_artist.id
        logger.warn "grant modification artist id mismatch #{@grant_submission.artist_id} != #{current_artist.id}"
        redirect_to "/"
        return
      end
    rescue
      redirect_to action: "index"
      return
    end
    
    render "modify"
  end
  
  def grant_contract_params
    params.permit(:id, :format, :submission_id)
  end
  
  def show
    if params[:id] == "generate_contract"
      show_contract
    else
      logger.warn "Asked to show something we don't understand"
      redirect_to "/"
    end
  end
  
  def show_contract
    begin
      submission = GrantSubmission.find(grant_contract_params[:submission_id])
    rescue
      redirect_to "/"
      return  
    end
    if submission.artist_id != current_artist.id && !admin_logged_in
      logger.warn "grant modification artist id mismatch #{@grant_submission.artist_id} != #{current_artist.id}"
      redirect_to "/"
      return
    end
    if !submission.funded 
      logger.warn "tried to generate contract for non-funded grant"
      redirect to "/"
    end
    grant_name = Grant.find(submission.grant_id).name
    artist_name = Artist.find(submission.artist_id).name
    
    respond_to do |format|
      format.html
      format.pdf do
        pdf = GrantContract.new(grant_name, submission.name, artist_name, submission.requested_funding_dollars)
        send_data pdf.render, filename: 
          "#{submission.name}_#{grant_name}_Contract_#{DateTime.current.strftime("%Y%m%d")}.pdf",
          type: "application/pdf"
      end
    end
  end
end
