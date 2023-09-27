
require File.expand_path('spec_helper', __FILE__)

#`require 'YC_Flutter_Bridge'` is not required because the spec_helper already
# Pods::Command::YC_Flutter_Bridge is defined in the cocoapods_plugin.rb
module Pod
  describe Command::Bridge do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ bridge }).should.be.instance_of Command::Bridge
      end
    end
  end
end
