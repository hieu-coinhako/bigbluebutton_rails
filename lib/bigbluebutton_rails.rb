require 'rails'

require 'classes/bigbluebutton_attendee'

module BigbluebuttonRails
  require 'browser'
  require 'resque'
  require 'resque-scheduler'
  require 'bigbluebutton_rails/rails'
  require 'bigbluebutton_rails/utils'
  require 'bigbluebutton_rails/controller_methods'
  require 'bigbluebutton_rails/internal_controller_methods'
  require 'bigbluebutton_rails/background_tasks'
  require 'bigbluebutton_rails/rails/routes'
  require 'bigbluebutton_rails/exceptions'
  require 'bigbluebutton_rails/dial_number'

  # Default controllers to generate the routes
  mattr_accessor :controllers
  @@controllers = {
    :servers => 'bigbluebutton/servers',
    :rooms => 'bigbluebutton/rooms',
    :recordings => 'bigbluebutton/recordings',
    :playback_types => 'bigbluebutton/playback_types'
  }

  # Default scope for routes
  mattr_accessor :routing_scope
  @@routing_scope = 'bigbluebutton'

  # Name of the metadata parameter that will contain the room's ID
  # when a room is created. Used to match the room of a recording when
  # recordings are fetched from the DB.
  # Has to be a symbol!
  mattr_accessor :metadata_room_id
  @@metadata_room_id = :'bbbrails-room-id'

  # Name of the metadata parameter that will contain the user's ID
  # when a room is created.
  # Has to be a symbol!
  mattr_accessor :metadata_user_id
  @@metadata_user_id = :'bbbrails-user-id'

  # Name of the metadata parameter that will contain the user's name
  # when a room is created.
  # Has to be a symbol!
  mattr_accessor :metadata_user_name
  @@metadata_user_name = :'bbbrails-user-name'

  # Name of the metadata parameter that will contain the room's invitation
  # URL, in case `invitation_url_method` is implemented by the application.
  # Has to be a symbol!
  mattr_accessor :metadata_invitation_url
  @@metadata_invitation_url = :'invitation-url'

  # List of invalid metadata keys. Invalid keys are usually keys that are
  # used by the gem and by the application. The application using this gem
  # can add items to this list as well.
  # All values added can be symbols or strings.
  mattr_accessor :metadata_invalid_keys
  @@metadata_invalid_keys =
    [ @@metadata_room_id,
      @@metadata_user_id,
      @@metadata_user_name,
      @@metadata_invitation_url ]

  # Name of the attribute of a user that defines his name/username.
  mattr_accessor :user_attr_name
  @@user_attr_name = :'name'

  # Name of the attribute of a user that defines his ID.
  mattr_accessor :user_attr_id
  @@user_attr_id = :'id'

  # Name of the method that returns the invitation URL of a room.
  # Must be implemented by the application, there's no default implemented in this gem.
  mattr_accessor :invitation_url_method
  @@invitation_url_method = :'invitation_url'

  # Name of the method that returns a hash of metadata to be added to create calls.
  # By default only the metadata created in the database and associated with the room
  # will be used. This method can be used to dynamically decide on which metadata to
  # use when a meeting is about to be created.
  # Receives the meeting as argument and must return a hash where keys are metadata keys
  # and values are the metadata values.
  mattr_accessor :dynamic_metadata_method
  @@dynamic_metadata_method = :'dynamic_metadata'

  # Whether or not the gem should pass the voice bridges set in the rooms when making
  # API calls. By default it is false, meaning that the voice bridge will never be
  # passed, so it will be generated by the web conference server. Setting it to true
  # will make the voice bridge set locally in the room to be used in the web conference
  # server. Notice that the voice bridge has to be unique in a web conference server, so
  # if you are setting the voice bridges manually, you will also have to make sure that
  # the voice bridges are unique (there's nothing in the gem to guarantee this uniqueness).
  mattr_accessor :use_local_voice_bridges
  @@use_local_voice_bridges = false

  # Finds the BigbluebuttonRoom associated with the recording data in 'data', if any.
  # TODO: if not found, remove the association or keep the old one?
  def self.match_room_recording(data)
    if block_given?
      yield
    else
      BigbluebuttonRoom.find_by_meetingid(data[:meetingid])
    end
  end

  def self.set_controllers(options)
    unless options.nil?
      @@controllers.merge!(options).slice!(:servers, :rooms, :recordings, :playback_types)
    end
  end

  # Default way to setup the gem.
  def self.setup
    yield self
  end

end
