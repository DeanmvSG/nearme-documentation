namespace :after_deploy do
  desc 'Runs required tasks after deployment'
  task :run => [:environment] do
    puts "Clearing cache"
    Rails.cache.clear
    RedisCache.clear

    puts "Removing all jobs from queue recurring-jobs"
    Delayed::Job.where(queue: "recurring-jobs").delete_all

    puts "Re-creating jobs for queue recurring-jobs"
    # and queuing them again
    ScrapeSupportEmails.schedule!
    SendRatingReminders.schedule!
    SchedulePaymentTransfers.schedule!
    SendSearchesDailyAlerts.schedule!
    PrepareFriendFinders.schedule!
    SendSearchesWeeklyAlerts.schedule!
    SendAnalyticsMails.schedule!
    SendUnreadMessagesReminders.schedule!
    SendSpamReportsSummaryDaily.schedule!
    ScheduleChargeSubscriptions.schedule! if Rails.env.production?
    ScheduleCommunityAggregatesCreation.schedule!

    puts "Creating default locales"
    Utils::EnLocalesSeeder.new.go!

    puts "Notifying Raygun about deployment"
    RaygunDeployNotifier.send!
  end

end

