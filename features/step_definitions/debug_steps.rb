When /^I eval: (.*)$/ do |ruby|
  p eval(ruby)
end

When /^I open page$/ do
  save_and_open_page
end

Then /^I debug$/ do
  debugger
end

Then /^I pry$/ do
  binding.pry
end