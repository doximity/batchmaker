# frozen_string_literal: true

class Batchmaker
  class NullLogger
    def error(msg); end

    def info(msg); end

    def debug(msg); end
  end
end
