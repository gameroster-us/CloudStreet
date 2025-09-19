#  Development : Metrics Design

Namespacing  
Always namespace your collected data, even if you only have one app for now.
If your app does two things at the same time like serving HTML and providing
an API, you might want to create two clients which you would namespace
differently.  
Naming metrics  
Properly naming your metrics is critical to avoid conflicts, confusing data
and potentially wrong interpretation later on. I like to organize metrics
using the following schema:  
1  
<namespace>.<instrumented section>.<target (noun)>.<action (past tense verb)>  
Example:  
1  
2  
3  
accounts.authentication.password.attempted  
accounts.authentication.password.succeeded  
accounts.authentication.password.failed  
I use nouns to define the target and past tense verbs to define the action.
This becomes a useful convention when you need to nest metrics. In the above
example, let’s say I want to monitor the reasons for the failed password
authentications. Here is how I would organize the extra stats:  
1  
2  
3  
accounts.authentication.password.failure.no_email_found  
accounts.authentication.password.failure.password_check_failed  
accounts.authentication.password.failure.password_reset_required  
As you can see, I used failure instead of failed in the stat name. The main
reason is to avoid conflicting data. failed is an action and already has a
data series allocated, if I were to add nested data using failed, the data
would be collected but the result would be confusing. The other reason is
because when we will graph the data, we will often want to use a wildcard * to
collect all nested data in a series.  
Graphite wild card usage example on counters:  
1  
accounts.authentication.password.failure.*  
This should give us the same value as accounts.authentication.password.failed,
so really, we should just collect the more detailed version and get rid of
accounts.authentication.password.failed.  
Following this naming convention should really help your data stay clean and
easy to manage.  
Counters and metrics  
StatsD lets you record different types of metrics as illustrated here.  
This article will focus on the 2 main types:  
counters  
timers  
Use counters for metrics when you don’t care about how long the code your are
instrumenting takes to run. Usually counters are used for data that have more
of a direct business value. Examples include sales, authentication, signups,
etc.  
Timers are more powerful because they can be used to analyze the time spent in
a piece of code but also be used as a counters. Most of my work involves
timers because I want to detect system anomalies including performance changes
and trends in the way code is being used.  
I usually use timers in a nested manner, starting when a request comes into
the system, through each of the various datastores, and ending with the
response.

  
<https://github.com/lukevenediger/statsd.net/blob/master/statsd.net/Documentat
ion/guidance/metric-anti-patterns.md>

  
Metric Anti-Patterns  
It can be a bit daunting to get started with metrics, and new users often
wrestle with how to build up their metric namespaces. There are lots of
approaches that work, which I'll discuss in another article, but this page
talks about patterns that you should avoid. One aspect you should always
remember when implementing metrics is that it's an ongoing process - you won't
get it right the first time (or second, or third). Rather, it's an ever-
evolving process of fine-tuning and requires feedback from live usage
scenarios to help you improve your metrics in the next release of your
software.

Anti-Pattern: Flattened Name-Value Pairs

A metric where a name node is followed by a value node to create a flattened
key-value pair chain.

Examples:

stats_counts.fooApp.page.AboutPage.button.Help.position.TopRight  
stats.timers.fooApp.report.MonthlySales.customerId.1304.generationTime.mean  
Suggestions

Remove the name nodes from the metric, just log the value.

stats_counts.fooApp.AboutPage.Help.TopRight  
Remarks

This can be avoided by deciding what each node position means for a particular
metric. In the first example, you could stipulate that zero-based position 2
is the page name, position 3 is the Section the user was on, and position 4
was the area of the screen they clicked.

Having fewer nodes in your namespace reduces the number of unique combinations
your metric could produce, and therefore saves on disk space when these
metrics are logged by Graphite.

Anti Pattern: Unique Identifiers in Metrics

A metric where one of the nodes is a unique, non-recurring value such as a
purchase ID, a session ID or even a Date Stamp.

Examples

stats_counts.fooApp.05-April-2013-17-06-10.Basket.ItemAdded - a date stamp at
node 2  
stats_counts.fooApp.Login.19958813 - a unique session ID at node 3  
Suggestions

Remove such unique data from metric names, as these metrics are likely to be
summed or averaged together anyways.

stats_counts.fooApp.Basket.ItemAdded  
stats_counts.fooApp.Login Since metrics are mostly about capturing trends on a
graph, there is no value in having these specific, one-time values present in
the metric name.  
Remarks

A larger system-level impact is the increased disk cost of having a greater
number of metric combinations being stored on Graphite. Each unique
combination of nodes results in a storage file being created. And, if you are
using Whisper and your data files are created with null-padding in the place
of data, you could quickly run out of disk space.

Anti-Pattern: Log everything in the same metric

In this anti-pattern, developers will log everything and anything so as not to
be left without data should there be an issue they need to investigate,
including fields for which there is no use case yet. These metrics often
include two or more dimensions describing the event being logged.

Examples

stats_counts.fooApp.MyApplicationDLL.ApplicationClass.ExecMethod.Customer.Bask
et.AddItem.ShippingCalculator.Free  
stats_counts.Auction.Cars.Won.Mazda.ReserveWasMet  
stats_counts.Auction.Cars.Won.Porsche.ReserveNotMet  
Suggestions

Aim for having one dimension per metric and log more than one metric for an
event. This will result in less pain when building up your query in Graphite.

stats_counts.fooApp.Customer.Basket.AddItem  
stats_counts.fooApp.Customer.AddItem.FreeShipping  
stats_counts.AuctionsWon.Cars.ReserveWasMet  
stats_counts.AuctionsWon.Cars.Mazda  
Don't include dimensions that you don't have an immediate use for. They will
simply make querying your graphs a whole lot harder.

Remarks

Having lots of dimensions causes your metric names to be overly long and will
make building queries difficult. Also consider how combining dimensions adds
to the number of parts of the metric you will need to 'star' out with wildcard
symbols *.

Anti-Pattern: Including Unique IDs In Metrics

A metric that contains a value that will never be repeated again.

Examples

stats_counts.AuctionsWon.1d290a8e-d42f-402a-bfbd-cc16369c256b.ReserveMet  
stats.timers.transactionTime.12496991.mean  
Suggestions

Avoid logging one-time data as part of a metric. Rather, log a non-specific
metric that indicates an event has taken place. If this is being added to
provide additional data for diagnostics then consider sending that data to a
log file or even an auditing system. Metrics are used to track events and
visualise activity, not for detailed system auditing.

Change the example above to:

stats_counts.AuctionsWon.ReserveMet  
stats.timers.transactionTime.mean  
Remarks

A practical reason behind avoiding uniques in a metric is the fact that
Graphite creates a new archive file for each new metric, causing a massive
rise in disk consumption. Each file will contain sparse data even though the
whole file has been allocated to hold as much data as the retention period
allows, wasting valuable disk space.

