require 'toml'
require 'stringio'
require 'minicron/cli'
require 'minicron/constants'

# @author James White <dev.jameswhite+minicron@gmail.com>
module Minicron
  # Default configuration, this can be overriden
  @config = {
    'global' => {
      'verbose' => false
    },
    'server' => {
      'scheme' => 'http',
      'host' => '127.0.0.1',
      'port' => 9292,
      'path' => '/',
      'connect_timeout' => 5,
      'inactivity_timeout' => 5
    },
    'database' => {
      'type' => 'mysql',
      'host' => '127.0.0.1',
      'database' => 'minicron',
      'username' => 'minicron',
      'password' => 'password'
    },
    'cli' => {
      'mode' => 'line',
      'dry_run' => false,
      'trace' => false
    }
  }

  class << self
    attr_accessor :config
  end

  # Parse the given config file and update the config hash
  #
  # @param file_path [String]
  def self.parse_file_config(file_path)
    file_path ||= DEFAULT_CONFIG_FILE

    begin
      @config = TOML.load_file(file_path)
    rescue Errno::ENOENT
      # Fail if the file doesn't exist unless it's the default config file
      if file_path != DEFAULT_CONFIG_FILE
        fail Exception, "Unable to the load the file '#{file_path}', are you sure it exists?", caller
      end
    rescue Errno::EACCES
      fail Exception, "Unable to the readthe file '#{file_path}', check it has the right permissions.", caller
    rescue TOML::ParseError
      fail Exception, "An error occured parsing the config file '#{file_path}', please check it uses valid TOML syntax.", caller
    end
  end

  # Parses the config options from the cli
  # @option options [Hash] global global options
  # @option options [Hash] server server options
  # @option options [Hash] cli cli options
  def self.parse_cli_config(options = {})
    options.each do |type, _|
      options[type].each do |key, value|
        if value
          @config[type][key] = value
        end
      end
    end
  end

  # Helper function to capture STDOUT and/or STDERR
  # adapted from http://stackoverflow.com/a/11349621/483271
  #
  # @option options [Symbol] type (:both) what to capture: :stdout, :stderr or :both
  # @return [StringIO] if the type was set to :stdout or :stderr
  # @return [Hash] containg both the StringIO instances if the type was set to :both
  def self.capture_output(options = {}, &block)
    # Default options
    options[:type] ||= :both

    # Make copies of the origin STDOUT/STDERR
    original_stdout = $stdout
    original_stderr = $stderr

    # Which are we handling?
    case options[:type]
    when :stdout
      $stdout = stdout = StringIO.new
    when :stderr
      $stderr = stderr = StringIO.new
    when :both
      $stderr = $stdout = stdout = stderr = StringIO.new
    else
      fail ArgumentError, 'The type must be one of [stdout, stderr, both]'
    end

    # Yield to the code block to do whatever it has to do
    begin
      yield
    # Whatever happens make sure we reset STDOUT/STDERR
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    # What are we going to return?
    case options[:type]
    when :stdout
      stdout
    when :stderr
      stderr
    else
      { :stdout => stdout, :stderr => stderr }
    end
  end
end
