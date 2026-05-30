# frozen_string_literal: true

# Base class for all Query objects.
# Subclasses implement `#call` as an instance method; `ApplicationQuery.call(...)`
# instantiates the subclass and delegates, keeping the external interface stable.
class ApplicationQuery
  def self.call(...)
    new(...).call
  end
end
