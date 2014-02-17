require 'spec_helper'

describe Minicron::CLI do
  describe '#run' do
    it 'should run a simple command and print the output to stdout' do
      Minicron::CLI.new.run(['run', 'echo hello', '--trace'], :trace => true) do |output|
        output.clean == 'hello'
      end
    end

    it 'should run a simple multi-line command and print the output to stdout' do
      Minicron::CLI.new.run(['run', 'ls -l', '--trace'], :trace => true) do |output|
        output.clean == `ls -l`.clean
      end
    end

    context 'when a non-existent command is run' do
      it 'should return an error' do
        Minicron.capture_output :type => :stderr do
          expect do
            Minicron::CLI.new.run(['lol'], :trace => true)
          end.to raise_error SystemExit
        end
      end
    end

    context 'when tracing is disabled but passed as an option' do
      it 'should raise SystemExit' do
        Minicron.capture_output :type => :stderr do
          expect do
            Minicron::CLI.new.run(['run', 'echo 1', '--trace'])
          end.to raise_error SystemExit
        end
      end
    end

    context 'when no argument is passed to the run action' do
      it 'should raise ArgumentError' do
        Minicron.capture_output :type => :stderr do
          expect do
            Minicron::CLI.new.run(['run', '--trace'], :trace => true)
          end.to raise_error ArgumentError
        end
      end
    end
  end

  describe '#run_command' do
    context 'when in verbose mode' do
      it 'a one line command should result in 7 total line' do
        minicron = Minicron::CLI.new
        minicron.disable_coloured_output!
        output = ''

        minicron.run_command('echo 1', :verbose => true) do |line|
          output += line[:output]
        end

        expect(output.split("\n").length).to eq 7
      end
    end
  end

  describe '#coloured_output?' do
    context 'when Rainbow is enabled' do
      it 'should return true' do
        Rainbow.enabled = true

        expect(Minicron::CLI.new.coloured_output?).to eq true
      end
    end

    context 'when Rainbow is disabled' do
      it 'should return false' do
        Rainbow.enabled = false

        expect(Minicron::CLI.new.coloured_output?).to eq false
      end
    end
  end

  describe '#enable_coloured_output!' do
    it 'should set Rainbow.enabled to true' do
      minicron = Minicron::CLI.new
      minicron.enable_coloured_output!

      expect(Rainbow.enabled).to eq true
      expect(minicron.coloured_output?).to eq true
    end
  end

  describe '#disable_coloured_output!' do
    it 'should set Rainbow.enabled to false' do
      minicron = Minicron::CLI.new
      minicron.disable_coloured_output!

      expect(Rainbow.enabled).to eq false
      expect(minicron.coloured_output?).to eq false
    end
  end
end
