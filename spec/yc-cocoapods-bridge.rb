
require File.expand_path('spec_helper', __FILE__)

#`require 'yc-cocoapods-bridge'` is not required because the spec_helper already
# Pods::Command::yc-cocoapods-bridge is defined in the cocoapods_plugin.rb
module Pod
  describe Command::Bridge do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ bridge }).should.be.instance_of Command::Bridge
      end
    end
  end
end
