require_relative './helper.rb'
require 'time'
require 'test/unit'

class TestParsing < Test::Unit::TestCase

  def setup
    Tickle.debug = (ARGV.detect {|a| a == '--d'})
    @verbose = (ARGV.detect {|a| a == '--v'})

    puts "Time.now"
    p Time.now

    @date = Date.today
  end

  def test_parse_best_guess_simple
    start = Date.new(2020, 04, 01)

    assert_date_match(@date + 1.day, 'each day')
    assert_date_match(@date + 1.day, 'every day')
    assert_date_match(@date + 1.week, 'every week')
    assert_date_match(@date + 1.month, 'every month')
    assert_date_match(@date + 1.year, 'every year')

    assert_date_match(@date + 1.day, 'daily')
    assert_date_match(@date + 1.week , 'weekly')
    assert_date_match(@date + 1.month , 'monthly')
    assert_date_match(@date + 1.year , 'yearly')

    assert_date_match(@date + 3.days, 'every 3 days')
    assert_date_match(@date + 3.weeks, 'every 3 weeks')
    assert_date_match(@date + 3.months, 'every 3 months')
    assert_date_match(@date + 3.years, 'every 3 years')

    assert_date_match(@date + 2.days, 'every other day')
    assert_date_match(@date + 2.weeks, 'every other week')
    assert_date_match(@date + 2.months, 'every other month')
    assert_date_match(@date + 2.years, 'every other year')

    assert_date_match(Chronic.parse('next monday', now: @date), 'every Monday')
    assert_date_match(Chronic.parse('next wednesday', now: @date), 'every Wednesday')
    assert_date_match(Chronic.parse('next friday', now: @date), 'every Friday')

    assert_date_match(Date.new(2021, 2, 1), 'every February', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 5, 1), 'every May', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 6, 1), 'every june', {:start => start, :now => start})

    assert_date_match(Chronic.parse('next sunday', now: @date), 'beginning of the week')
    assert_date_match(Chronic.parse('next wednesday', now: @date), 'middle of the week')
    assert_date_match(Chronic.parse('next saturday', now: @date), 'end of the week')

    assert_date_match(Date.new(2020, 05, 01), 'beginning of the month', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 15), 'middle of the month', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 30), 'end of the month', {:start => start, :now => start})

    assert_date_match(Date.new(2021, 01, 01), 'beginning of the year', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 06, 15), 'middle of the year', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 12, 31), 'end of the year', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 05, 03), 'the 3rd of May', {:start => start, :now => start})
    assert_date_match(Date.new(2021, 02, 03), 'the 3rd of February', {:start => start, :now => start})
    assert_date_match(Date.new(2022, 02, 03), 'the 3rd of February 2022', {:start => start, :now => start})
    assert_date_match(Date.new(2022, 02, 03), 'the 3rd of Feb, 2022', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 04, 04), 'the 4th of the month', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 10), 'the 10th of the month', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 10), 'the tenth of the month', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 05, 01), 'first', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 05, 01), 'the first of the month', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 30), 'the thirtieth', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 05), 'the fifth', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 05, 01), 'the 1st Wednesday of the month', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 05, 17), 'the 3rd Sunday of May', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 19), 'the 3rd Sunday of the month', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 06, 23), 'the 23rd of June', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 06, 23), 'the twenty third of June', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 07, 31), 'the thirty first of July', {:start => start, :now => start})

    assert_date_match(Date.new(2020, 04, 21), 'the twenty first', {:start => start, :now => start})
    assert_date_match(Date.new(2020, 04, 21), 'the twenty first of the month', {:start => start, :now => start})
  end

  def test_parse_best_guess_complex
    start = Date.new(2020, 04, 01)

    assert_tickle_match(@date + 1.day, @date, @date + 1.week, 'day', 'starting today and ending one week from now') if Time.now.hour < 21 # => demonstrates leaving out the actual time period and implying it as daily
    assert_tickle_match(@date + 1.day, @date + 1.day, @date + 1.week, 'day','starting tomorrow and ending one week from now') # => demonstrates leaving out the actual time period and implying it as daily.

    assert_tickle_match(Chronic.parse('next monday', now: @date), Chronic.parse('next monday', now: @date), nil, 'month', 'starting Monday repeat every month')

    year = @date >= Date.new(@date.year, 5, 13) ? @date + 1.year : @date.year
    assert_tickle_match(Date.new(year, 05, 13), Date.new(year, 05, 13), nil, 'week', 'starting May 13th repeat every week')
    assert_tickle_match(Date.new(year, 05, 13), Date.new(year, 05, 13), nil, 'other day', 'starting May 13th repeat every other day')
    assert_tickle_match(Date.new(year, 05, 13), Date.new(year, 05, 13), nil, 'other day', 'every other day starts May 13th')
    assert_tickle_match(Date.new(year, 05, 13), Date.new(year, 05, 13), nil, 'other day', 'every other day starts May 13')
    assert_tickle_match(Date.new(year, 05, 13), Date.new(year, 05, 13), nil, 'other day', 'every other day starting May 13th')
    assert_tickle_match(Date.new(year, 05, 13), Date.new(year, 05, 13), nil, 'other day', 'every other day starting May 13')

    assert_tickle_match(Chronic.parse('next wednesday', now: @date), Chronic.parse('next wednesday', now: @date), nil, 'week', 'every week starts this wednesday')
    assert_tickle_match(Chronic.parse('next wednesday', now: @date), Chronic.parse('next wednesday', now: @date), nil, 'week', 'every week starting this wednesday')

    assert_tickle_match(Date.new(2021, 05, 01), Date.new(2021, 05, 01), nil, 'other day', "every other day starting May 1st #{(start + 1.year).year}")
    assert_tickle_match(Date.new(2021, 05, 01), Date.new(2021, 05, 01), nil, 'other day',  "every other day starting May 1 #{(start + 1.year).year}")
    assert_tickle_match(Chronic.parse('next sunday', now: @date), Chronic.parse('next sunday', now: @date),  nil, 'other week',  'every other week starting this Sunday')

    assert_tickle_match(Chronic.parse('next wednesday', now: @date), Chronic.parse('next wednesday', now: @date), Date.new(year, 05, 13), 'week', 'every week starting this wednesday until May 13th')
    assert_tickle_match(Chronic.parse('next wednesday', now: @date), Chronic.parse('next wednesday', now: @date), Date.new(year, 05, 13), 'week', 'every week starting this wednesday ends May 13th')
    assert_tickle_match(Chronic.parse('next wednesday', now: @date), Chronic.parse('next wednesday', now: @date), Date.new(year, 05, 13), 'week', 'every week starting this wednesday ending May 13th')
  end

  def test_tickle_args
    actual_next_only = parse_now('May 1st, 2020', {:next_only => true}).to_date
    assert(Date.new(2020, 05, 01).to_date == actual_next_only, "\"May 1st, 2011\" :next parses to #{actual_next_only} but should be equal to #{Date.new(2020, 05, 01).to_date}")

    start_date = Time.now
    assert_tickle_match(start_date + 3.days, @date, nil, '3 days', 'every 3 days', {:start => start_date})
    assert_tickle_match(start_date + 3.weeks, @date, nil, '3 weeks', 'every 3 weeks', {:start => start_date})
    assert_tickle_match(start_date + 3.months, @date, nil, '3 months', 'every 3 months', {:start => start_date})
    assert_tickle_match(start_date + 3.years, @date, nil, '3 years', 'every 3 years', {:start => start_date})

    end_date = (Date.today + 5.months).to_time
    assert_tickle_match(start_date + 3.days, @date, start_date + 5.months, '3 days', 'every 3 days', {:start => start_date, :until  => end_date})
    assert_tickle_match(start_date + 3.weeks, @date, start_date + 5.months, '3 weeks', 'every 3 weeks', {:start => start_date, :until  => end_date})
    assert_tickle_match(start_date + 3.months, @date, start_date + 5.months, '3 months', 'every 3 months', {:until => end_date})
  end

  # def test_us_holidays
  #   start = Date.new(2020, 01, 01)
  #   assert_date_match(Date.new(2021, 1, 1), 'New Years Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 1, 20), 'Inauguration', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 1, 20), 'Martin Luther King Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 1, 20), 'MLK', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 2, 17), 'Presidents Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 5, 25), 'Memorial Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 7, 4), 'Independence Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 9, 7), 'Labor Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 10, 12), 'Columbus Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 11, 11), 'Veterans Day', {:start => start, :now => start})
  #   # assert_date_match(Date.new(2020, 11, 26), 'Thanksgiving', {:start => start, :now => start})  # Chronic returning incorrect date.  Routine is correct
  #   assert_date_match(Date.new(2020, 12, 25), 'Christmas', {:start => start, :now => start})

  #   assert_date_match(Date.new(2020, 2, 2), 'Super Bowl Sunday', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 2, 2), 'Groundhog Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 2, 14), "Valentine's Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 3, 17), "Saint Patrick's day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 4, 1), "April Fools Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 4, 22), "Earth Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 4, 24), "Arbor Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 5, 5), "Cinco De Mayo", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 5, 10), "Mother's Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 6, 14), "Flag Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 6, 21), "Fathers Day", {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 10, 31), "Halloween", {:start => start, :now => start})
  #   # assert_date_match(Date.new(2020, 11, 10), "Election Day", {:start => start, :now => start}) # Damn Chronic again.  Expression is correct
  #   assert_date_match(Date.new(2020, 12, 25), 'Christmas Day', {:start => start, :now => start})
  #   assert_date_match(Date.new(2020, 12, 24), 'Christmas Eve', {:start => start, :now => start})
  #   assert_date_match(Date.new(2021, 1, 1), 'Kwanzaa', {:start => start, :now => start})

  # end

  def test_argument_validation
    assert_raise(Tickle::InvalidArgumentException) do
      time = Tickle.parse("may 27", :today => 'something odd')
    end

    assert_raise(Tickle::InvalidArgumentException) do
      time = Tickle.parse("may 27", :foo => :bar)
    end

    assert_raise(Tickle::InvalidArgumentException) do
      time = Tickle.parse(nil)
    end

    assert_raise(Tickle::InvalidArgumentException) do
      time = Tickle.parse('every other day', start: 'invalid')
    end

    assert_raise(Tickle::InvalidDateExpression) do
      past_date = Date.civil(Date.today.year, Date.today.month, Date.today.day - 1)
      time = Tickle.parse("every other day", {:start => past_date})
    end

    assert_raise(Tickle::InvalidDateExpression) do
      time = Tickle.parse('every other day starting invalid')
    end

    assert_raise(Tickle::InvalidDateExpression) do
      time = Tickle.parse('every other day ending invalid')
    end

    assert_raise(Tickle::InvalidDateExpression) do
      start_date = Date.today + 10.days
      end_date = Date.today + 5.days
      time = Tickle.parse("every other day", :start => start_date, :until => end_date)
    end

    assert_raise(Tickle::InvalidDateExpression) do
      end_date = Date.civil(Date.today.year, Date.today.month+2, Date.today.day)
      parse_now('every 3 months', {:until => end_date})
    end
  end

  private
  def parse_now(string, options={})
    out = Tickle.parse(string, {}.merge(options))
    puts (options.empty? ?  ("Tickle.parse('#{string}')\n\r  #=> #{out}\n\r") : ("Tickle.parse('#{string}', #{options})\n\r  #=> #{out}\n\r")) if @verbose
    out
  end

  def assert_date_match(expected_next, date_expression, options={})
    actual_next = parse_now(date_expression, options)[:next].to_date
    assert (expected_next.to_date == actual_next.to_date), "\"#{date_expression}\" parses to #{actual_next} but should be equal to #{expected_next}"
  end

  def assert_tickle_match(expected_next, expected_start, expected_until, expected_expression, date_expression, options={})
    result = parse_now(date_expression, options)
    actual_next = result[:next].to_date
    actual_start = result[:starting].to_date
    actual_until = result[:until].to_date rescue nil
    expected_until = expected_until.to_date rescue nil
    actual_expression = result[:expression]

    assert (expected_next.to_date == actual_next.to_date), "\"#{date_expression}\" :next parses to #{actual_next} but should be equal to #{expected_next}"
    assert (expected_start.to_date == actual_start.to_date), "\"#{date_expression}\" :starting parses to #{actual_start} but should be equal to #{expected_start}"
    assert (expected_until == actual_until), "\"#{date_expression}\" :until parses to #{actual_until} but should be equal to #{expected_until}"
    assert (expected_expression == actual_expression), "\"#{date_expression}\" :expression parses to \"#{actual_expression}\" but should be equal to \"#{expected_expression}\""
  end

end
