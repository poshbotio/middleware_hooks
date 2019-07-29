# threadbot.channel.md

## Overview

Suggest Slack threads for busy rooms with a lot of messages occurring outside of threads at the channel level to remind users to use threads.
Threads help keep context and a helpful reminder as linear messages keep getting posted might help encourage more threaded discussion.
Original core code was written by Brandon and can be reviewed in this post [Poshbot Middleware for Rate Limiting](https://devblackops.io/poshbot-middleware-for-ratelimiting/).
This was subsequently modified by Sheldon Hull to focus on channel rate instead of individual rate, and provide various randomized positive and reminder reactions documented below.

## Configuration

The variables for

| Variable               | Default | Purpose                                                                                                                                                                              |
| ---------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| MaximumMessages        | 6       | Throttle goal for maximum messages to consider ok in a channel before posting a message                                                                                              |
| TimePeriodToMonitorSec | 900     | Minutes to allow for monitoring the maximum message. Example 7 messages in 13 minutes would exceed the limit of 6 and generate a response, as well as reactions at approx 3 messages |

## Expected Behavior

```gherkin
Scenario: A channel begins to post messages without using threads to reduce noise
Given the channel is allowed 6 messages
And the timeperiod for monitoring is 15 minutes
When a user hits 4 messages :eyes: reactions begin to appear from the bot
And when a user exceeds the <allowed count> then a randomized message is posting encouraging threaded discussion
And the counter is reset for another <allowed count>
```

```gherkin
Scenario: A channel leverages threaded messages correctly
Given the channel is using threaded messages
When users post in a threaded discussion
Then randomly a positive reaction is posted to encourage threaded messages
```

## 🤝 Contributors

- [Brandon Olin](https://devblackops.io)
- [Sheldon Hull](https://www.sheldonhull.com)

## Show your support

Give a ⭐️ if this project helped you!
