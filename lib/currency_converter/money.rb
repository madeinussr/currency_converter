module CurrencyConverter
  class Money
    include Comparable

    class Configuration
      attr_accessor :base_currency, :rates

      def initialize(base_currency, rates)
        raise ArgumentError.new('Should provide base currency') unless base_currency
        @base_currency = base_currency.to_s
        @rates = rates.each_with_object({}) { |(k, v), new_hash| new_hash[k.to_s] = v.to_f }
      end
    end

    class << self
      attr_reader :configuration
    end

    def self.conversion_rates(base_currency, rates={})
      @configuration = Configuration.new(base_currency, rates)
      self
    end

    attr_reader :amount, :currency

    def initialize(amount, currency)
      raise_unknown_currency unless known_currency?(currency)
      
      @amount = amount.to_f.round(2)
      @currency = currency
    end

    def convert_to(currency_name)
      raise_unknown_currency unless known_currency?(currency_name)

      return self if currency_name == currency

      converted_amount = convert_amount_to(currency_name)
      self.class.new(converted_amount, currency_name)
    end

    def inspect
      "#{'%.2f' % amount} #{currency}"
    end

    def to_s
      inspect
    end

    def +(object)
      do_arithmetics_with(object, :+)
    end

    def -(object)
      do_arithmetics_with(object, :-)
    end

    def /(object)
      do_arithmetics_with(object, :/)
    end

    def *(object)
      do_arithmetics_with(object, :*)
    end

    def <=>(compared_object)
      return nil unless compared_object.is_a?(CurrencyConverter::Money)

      amount <=> compared_object.convert_to(self.currency).amount
    end

    private

    def convert_amount_to(to_currency)
      config = self.class.configuration

      if self.currency == config.base_currency
        self.amount * config.rates[to_currency]
      else
        if to_currency == config.base_currency
          self.amount / config.rates[self.currency]
        else
          self.amount / config.rates[self.currency] * config.rates[to_currency]
        end
      end
    end

    def known_currency?(currency)
      config = self.class.configuration
      config.base_currency == currency || config.rates.keys.include?(currency)
    end

    def raise_unknown_currency
      raise ArgumentError.new('Unknown currency. Please, configure via .conversion_rates')
    end

    def do_arithmetics_with(object, method_name)
      first_amount = self.amount
      second_amount = if object.is_a?(CurrencyConverter::Money)
        object.convert_to(self.currency).amount
      else
        object.to_f rescue raise TypeError.new("Can't convert #{object.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
      end

      self.class.new(first_amount.send(method_name, second_amount), self.currency)
    end

    def compare_with(compared_object, method_name)
      return false unless compared_object.is_a?(CurrencyConverter::Money)

      self.amount.send(method_name, compared_object.convert_to(self.currency))
    end
  end
end