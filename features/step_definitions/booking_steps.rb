When(/^I follow the booking link for "([^"]*)"$/) do |date|
  date = Date.parse(date)
  find(:xpath, "//time[@datetime='#{date}']/../div/a").click
end

Then (/^I should not see the booking link for "([^"]*)"$/) do |date|
  date = Date.parse(date)
  page.should_not have_xpath("//time[@datetime='#{date}']/../details/a")
end

When(/^I try to book at #{capture_model} on "([^"]*)"$/) do |workplace_instance, date|
  workplace = model!(workplace_instance)
  date = Date.parse(date)
  visit "/workplaces/#{workplace.to_param}/bookings/new?date=#{date}"
end


Given /^the workplace has the following bookings:$/ do |table|
  table.hashes.each do |row|
    num = row["Number of Bookings"].to_i
    Given %'#{num} bookings exist with workplace: the workplace, date: "#{row["Date"]}"'
  end
end

Then /^I should see the following availability:$/ do |table|
  actual_availability = all("table.bookings td.day").inject({}) do |hash, cell|
    hash.tap do |hash|
      within(:xpath, cell.path) do
        date       = find("time")["datetime"]
        available  = find(".details").text.strip
        hash[date] = available
      end
    end
  end

  table.hashes.each do |date, available|
    actual_availability[date].should == available
  end
end

Then /^I should see the following bookings in order:$/ do |table|
  found    = all("ul.bookings li > p").map { |b| b.text.gsub(/\n\s*/,' ').strip }
  expected = table.raw.flatten

  found.should == expected
end

When(/^I cancel the booking for "([^"]*)"$/) do |date|
  date = Date.parse(date)
  within(:css, "li[data-date='#{date}']") do
    find(:css, "input[value='Cancel']").click
  end
end

Then /^I should see availability for dates:$/ do |table|
  dates = all("table.bookings td.day time").map {|t| t["datetime"]}
  dates.should == table.raw.flatten
end

Then /^I should not see availability for dates:$/ do |table|
  dates = all("table.bookings td.day time").map {|t| t["datetime"]}
  table.raw.flatten.each do |date|
    dates.should_not include(date)
  end
end

Given /^the following bookings are made for the workplace:$/ do |table|
  users = {}

  table.hashes.each do |row|
    user = users[row['User']] ||= FactoryGirl.create(:user, :name => row['User'])
    Timecop.freeze(Time.parse row['At'])
    Booking.create(
      :user      => user,
      :workplace => model!('the workplace'),
      :date      => Date.parse(row['For'])
    )
    Timecop.return
  end
end

Then /^I should see the following booking events in the feed in order:$/ do |table|
  regex = /<img[^>]+>\s*(.*?)\s+booked a desk for the (\d\d [A-Za-z]+, \d\d\d\d).*datetime="(.*?)"/m
  feeds = all("dl.activity_feed dd.feed_item.booked").map do |booked_item|
    user, date, at = *booked_item.native.to_s.scan(regex).first
    [user, Date.parse(date), Time.parse(at)]
  end

  table = table.hashes.map do |row|
    user, date, at = *row.values_at('User', 'For', 'At')
    [user, Date.parse(date), Time.parse(at)]
  end

  feeds.should == table
end

