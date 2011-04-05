require 'bigbluebutton-api'

class Bigbluebutton::RoomsController < ApplicationController

  # TODO create filter find_room

  before_filter :find_server
  respond_to :html, :except => :running
  respond_to :json, :only => :running

  def index
    # TODO restrict to rooms belonging to the selected server
    respond_with(@rooms = BigbluebuttonRoom.all)
  end

  def show
    respond_with(@room = BigbluebuttonRoom.find(params[:id]))
  end

  def new
    respond_with(@room = BigbluebuttonRoom.new)
  end

  def edit
    respond_with(@room = BigbluebuttonRoom.find(params[:id]))
  end

  def create
    @room = BigbluebuttonRoom.new(params[:bigbluebutton_room])
    @room.server = @server

    # TODO Generate a random meeting_id everytime a room is created
    if !params[:bigbluebutton_room].has_key?(:meeting_id) or
        params[:bigbluebutton_room][:meeting_id].blank?
      @room.meeting_id = @room.name
    end

    respond_with @room do |format|
      if @room.save
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.create.success')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @room = BigbluebuttonRoom.find(params[:id])

    if !params[:bigbluebutton_room].has_key?(:meeting_id) or
        params[:bigbluebutton_room][:meeting_id].blank?
      params[:bigbluebutton_room][:meeting_id] = params[:bigbluebutton_room][:name]
    end

    respond_with @room do |format|
      if @room.update_attributes(params[:bigbluebutton_room])
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.update.success')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @room = BigbluebuttonRoom.find(params[:id])

    # TODO Destroy room even if end_meeting failed?

    begin
      bbb_end_meeting if bbb_is_meeting_running?
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      # TODO Better error message: "Room destroyed in DB, but not in BBB..."
    end

    @room.destroy
    redirect_to(bigbluebutton_server_rooms_url)
  end

  def join
    @room = BigbluebuttonRoom.find(params[:id])
    role = bigbluebutton_role(@room)

    begin

      # if the current user is a moderator, create the room (if needed)
      # and join it
      if role == :moderator
        bbb_create_room unless bbb_is_meeting_running?
        join_url = bbb_join_url(bigbluebutton_user.name, role)
        redirect_to(join_url)

      # normal user only joins if the conference is running
      # if it's not, wait for a moderator to create the conference
      else
        if bbb_is_meeting_running?
          join_url = bbb_join_url(bigbluebutton_user.name, role)
          redirect_to(join_url)
        else
          render :action => :join_wait
        end
      end

    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      redirect_to request.referer
    end

  end

  def join_wait
  end

  def running
    @room = BigbluebuttonRoom.find(params[:id])

    begin
      run = bbb_is_meeting_running?
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      render :json => { running: "false", error: "#{e.to_s}" }
      #redirect_to request.referer
    else
      render :json => { running: "#{run}" }
    end

  end

  def end
    @room = BigbluebuttonRoom.find(params[:id])

    begin
      if bbb_is_meeting_running?
        bbb_end_meeting
        message = t('bigbluebutton_rails.rooms.notice.end.success')
      else
        message = t('bigbluebutton_rails.rooms.notice.end.not_running')
      end
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      redirect_to request.referer
    else
      redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
    end

  end

  protected

  def find_server
    if params.has_key?(:server_id)
      @server = BigbluebuttonServer.find(params[:server_id])
    else
      @server = BigbluebuttonServer.first
    end
  end


  #
  # Functions that directly call the BBB API. All prefixed with bbb_
  #

  def bbb_is_meeting_running?
    @server.api.is_meeting_running?(@room.meeting_id)
  end

  def bbb_end_meeting
    @server.api.end_meeting(@room.meeting_id, @room.moderator_password)
  end

  def bbb_create_room
    @server.api.create_meeting(@room.name, @room.meeting_id,
                               @room.moderator_password, @room.attendee_password,
                               @room.welcome_msg)
  end

  def bbb_join_url(username, role)
    if role == :moderator
      @server.api.join_meeting_url(@room.meeting_id, username,
                                   @room.moderator_password)
    else
      @server.api.join_meeting_url(@room.meeting_id, username,
                                   @room.attendee_password)
    end
  end

end