# frozen_string_literal: true

require "helper"

class TestLogAdapter < BridgetownUnitTest
  class LoggerDouble
    attr_accessor :level

    def debug(*); end

    def info(*); end

    def warn(*); end

    def error(*); end
  end

  context "#log_level=" do
    should "set the writers logging level" do
      subject = Bridgetown::LogAdapter.new(LoggerDouble.new)
      subject.log_level = :error
      assert_equal Bridgetown::LogAdapter::LOG_LEVELS[:error], subject.writer.level
    end
  end

  context "#adjust_verbosity" do
    should "set the writers logging level to error when quiet" do
      subject = Bridgetown::LogAdapter.new(LoggerDouble.new)
      subject.adjust_verbosity(quiet: true)
      assert_equal Bridgetown::LogAdapter::LOG_LEVELS[:error], subject.writer.level
    end

    should "set the writers logging level to debug when verbose" do
      subject = Bridgetown::LogAdapter.new(LoggerDouble.new)
      subject.adjust_verbosity(verbose: true)
      assert_equal Bridgetown::LogAdapter::LOG_LEVELS[:debug], subject.writer.level
    end

    should "set the writers logging level to error when quiet and verbose are both set" do
      subject = Bridgetown::LogAdapter.new(LoggerDouble.new)
      subject.adjust_verbosity(quiet: true, verbose: true)
      assert_equal Bridgetown::LogAdapter::LOG_LEVELS[:error], subject.writer.level
    end

    should "not change the writer's logging level when neither verbose or quiet" do
      subject = Bridgetown::LogAdapter.new(LoggerDouble.new)
      original_level = subject.writer.level
      refute_equal Bridgetown::LogAdapter::LOG_LEVELS[:error], subject.writer.level
      refute_equal Bridgetown::LogAdapter::LOG_LEVELS[:debug], subject.writer.level
      subject.adjust_verbosity(quiet: false, verbose: false)
      assert_equal original_level, subject.writer.level
    end

    should "call #debug on writer return true" do
      writer = Minitest::Mock.new(LoggerDouble.new)
      writer.expect :debug, true, ["  Logging at level: debug"]

      logger = Bridgetown::LogAdapter.new(writer, :debug)
      assert logger.adjust_verbosity
      writer.verify
    end
  end

  context "#debug" do
    should "call #debug on writer return true" do
      writer = Minitest::Mock.new(LoggerDouble.new)
      writer.expect :debug, true, ["#{"topic ".rjust(20)}log message"]
      logger = Bridgetown::LogAdapter.new(writer, :debug)

      assert logger.debug("topic", "log message")
    end
  end

  context "#info" do
    should "call #info on writer return true" do
      writer = Minitest::Mock.new(LoggerDouble.new)
      writer.expect :info, true, ["#{"topic ".rjust(20)}log message"]
      logger = Bridgetown::LogAdapter.new(writer, :info)

      assert logger.info("topic", "log message")
    end
  end

  context "#warn" do
    should "call #warn on writer return true" do
      writer = Minitest::Mock.new(LoggerDouble.new)
      writer.expect :warn, true, ["#{"topic ".rjust(20)}log message"]
      logger = Bridgetown::LogAdapter.new(writer, :warn)

      assert logger.warn("topic", "log message")
    end
  end

  context "#error" do
    should "call #error on writer return true" do
      writer = Minitest::Mock.new(LoggerDouble.new)
      writer.expect :error, true, ["#{"topic ".rjust(20)}log message"]
      logger = Bridgetown::LogAdapter.new(writer, :error)

      assert logger.error("topic", "log message")
    end
  end

  context "#abort_with" do
    should "call #error and abort" do
      logger = Bridgetown::LogAdapter.new(LoggerDouble.new, :error)
      mock = Minitest::Mock.new
      mock.expect :call, true, ["topic", "log message"]
      logger.stub :error, mock do
        assert_raises(SystemExit) { logger.abort_with("topic", "log message") }
      end
    end
  end

  context "#messages" do
    should "return an array" do
      assert_equal [], Bridgetown::LogAdapter.new(LoggerDouble.new).messages
    end

    should "store each log value in the array" do
      logger = Bridgetown::LogAdapter.new(LoggerDouble.new, :debug)
      values = %w(one two three four)
      logger.debug(values[0])
      logger.info(values[1])
      logger.warn(values[2])
      logger.error(values[3])
      assert_equal values.map { |value| "#{value} ".rjust(20) }, logger.messages
    end
  end

  context "#write_message?" do
    should "return false up to the desired logging level" do
      subject = Bridgetown::LogAdapter.new(LoggerDouble.new, :warn)
      refute subject.write_message?(:debug), "Should not print debug messages"
      refute subject.write_message?(:info), "Should not print info messages"
      assert subject.write_message?(:warn), "Should print warn messages"
      assert subject.write_message?(:error), "Should print error messages"
    end
  end
end
