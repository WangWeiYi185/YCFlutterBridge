require File.expand_path('../spec_helper', __FILE__)
RSpec.describe YCFlutterBridge do
  it "has a version number" do
    expect(YCFlutterBridge::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end



module Pod
  describe Command::Bridge do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ bridge }).should.be.instance_of Command::Bridge
      end
    end
  end
end


