require "bigbluebutton_api"

def mock_server_and_api
  # standard server mocks
  @api_mock = double(BigBlueButton::BigBlueButtonApi)
  @server_mock = stub_model(BigbluebuttonServer, id: 1, slug: "any")
  @server_mock.stub(:api) { @api_mock }
  BigbluebuttonServer.stub(:find) { @server_mock }
  BigbluebuttonServer.stub(:find_by) { @server_mock }

  # when testing rooms
  if defined?(room) and not room.nil?
    room.stub(:select_server) { @server_mock }
    BigbluebuttonRoom.stub(:find_by) { room }
    BigbluebuttonRoom.stub(:find) { room }
  end

  # when testing recordings
  unless not defined?(recording) or recording.nil?
    recording.room.stub(:server) { nil } # to make sure room.server is not used!
    recording.stub(:server) { @server_mock }
    BigbluebuttonRecording.stub(:find_by_recordid) { recording }
    BigbluebuttonRecording.stub(:find) { recording }
  end
end

def mocked_server
  @server_mock
end

def mocked_api
  @api_mock
end
