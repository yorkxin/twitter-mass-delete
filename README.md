# Delete Twitter Contents -- A Programmer's Guide

Here are some tools I used to remove data from Twitter.

**Project Policy**: I do not accept any patches. This
is because when I publish these code, I've already done my job
which is remove data I authored on Twitter. It makes no sense
to maintain the code here. These code exist for reference purpose
so that potentially other people can save time investigating
tools and problems that I ran into in 2022. If you find any bug, 
I encourage you to push your changes to your own origin.

## Requirements

* `jq` - https://stedolan.github.io/jq/
* `parallel` - [GNU Parallel](https://www.gnu.org/software/parallel/)
* `twurl` - https://github.com/twitter/twurl, which depends on `ruby`
  * In case you have issue running `twurl` on your machine, [check out here](https://developer.twitter.com/en/docs/twitter-api/tools-and-libraries/v1) for some alternative tools.
* `node` - [Node.js](https://nodejs.org/), required if you need to extract data from Twitter Archive
* Your personal Twitter API v1.1 Application. See usage in `twurl`'s README.

## Before you do

* Deleting your data on Twitter is a destructive, non-reversible operation. Think again before you delete anything.
* It is recommended that you download Twitter Archive before deleting anything in a mass.
* The author of this software does not provide any warranty, as stated in `LICENSE`. USE AT YOUR OWN RISK.

## General Guides for GNU Parallel

* `--resume --joblog +xxx.joblog` flags allow you to pause and resume.
  * Use `--resume-failed` or `--retry-failed` with the same `--joblog` for resume or retry.
* `--delay 0.1 -j 1` maxes out the default Twitter v1.1 API rate limit (9000 requests per 15 minutes)
  * `-j 1` means only run 1 worker. By default, GNU Parallel run N processes if your computer have N logical processors. 
  * Note: if you happen to use Twitter API 2.0, since it has lower rate limits. you may need to adjust `--delay` value.

## Tweets

### Extracting Tweets from Archive

Request and download an archive of your Twitter data from Twitter Web's Settings page.
Unzip the Zip archive file you received. Let's say you unzipped the files into `~/Downloads/twitter-xxx`:

1. Convert JavaScript objects to JSON stream:
   ```shell
   node extract-from-archive.js ~/Downloads/twitter-xxxx/data/tweet.js > full-from-archive.jsonl
   cat full-from-archive.jsonl | jq --slurp --raw-output -c '.[] | {"id_str":.id_str,"created_at":(.created_at|strptime("%a %b %d %H:%M:%S +0000 %Y")|todateiso8601),"text":.full_text}' | jq --slurp --raw-output -c "sort_by(.created_at)" > summary-from-archive.jsonl
   ```
   You'll get `full-from-archive.jsonl` and `summary-from-archive.jsonl` files. 

   The results may contain Retweets, which is not distinguishable from the JSON data (see caveats below).

   If you have issue running `node` on your machine, try open the `tweet.js` file with 
   a text editor (one that supports MB+ large files, such as SublimeText or BBEdit),
   remove the statement `window.YTD.tweet.part0 = ` in the first line, then save it as `tweet.json`.
   After all it's just a JSON literal assigned to a global object.

2. Extract Retweets
   ```shell
   cat summary-from-archive.jsonl | jq --raw-output -c 'select(.text | startswith("RT @"))' > summary-retweets.jsonl
   ```
   You'll get `summary-retweets.jsonl` file.
3. Extract Original Tweets
   ```shell
   cat summary-from-archive.jsonl | jq --raw-output -c 'select(.text | startswith("RT @") != true )' > summary-posts.jsonl
   ```
   You'll get `summary-posts.jsonl` file.

### Alternative: Download Tweets from API

```shell
./download-tweets.sh <screen_name>
```
You'll get `tweets.*.jsonl` in the current directory. There may be duplicates.

The API only return **most recent 3200** tweets, so this list may be incomplete.

The results may contain Retweets. Unfortunately the author did not have a chance
to confirm if they are mixed. The author did find a way to separate Retweets from
original tweets in the Twitter Archive, as noted below. You may find some ideas there.

### Caveats: Distinguishing Retweets

Distinguishing retweets is important because in Twitter API v1.1, 
'destroy a tweet' endpoint does not accept a Retweet, and 'destroy a retweet' 
does not accept an original Tweet.

For historical reason, a "Retweet" may not be distinguishable from API response, but can only be
told by checking if the text has `RT @` prefix. If you've been using Twitter since its early
days (pre-2010), you might remember there was no "Retweet" feature at that time. Instead,
people use `RT @user: <original text>` to denote a "retweet". It looks like Twitter
followed that convention, but the Twitter Archive does not distinguish them in the JSON
data, at least that's what the author found in mid 2022.

That means, matching `RT @` prefix may produce false positive results. You can
write a tweet starting with `RT @` but it's not a retweet.

If you see any error when running 'Delete Retweets' below, try putting those failed ids together,
then run 'Delete Tweets' instead.

### Delete Tweets

```shell
./delete-tweet.sh <tweet_id>
```

Batch delete tweets listed in `summary-posts.jsonl` produced above:

```shell
cat summary-posts.jsonl  | jq --raw-output '.id_str' | parallel -k —bar --delay 0.1 --resume --joblog +delete-tweets.joblog ./delete-tweet.sh
```

### Delete Retweets (Un-Retweet)

```shell
./unretweet.sh <tweet_id>
```

Batch delete retweets listed in `summary-retweets.jsonl` produced above:

```shell
cat summary-retweets.jsonl  | jq --raw-output '.id_str' | parallel -k --delay 0.1 --bar --resume --joblog +unretweet.joblog ./unretweet.sh
```

## Likes (fka. Favorites)

### Download Likes

```shell
./download-likes.sh <screen_name>
```

You'll get `likes.*.jsonl` in the current directory. There may be duplicates.

Note that Twitter Archive does not contain Like ID of all like entries (only tweet ID). To delete a like, the Like ID is required.

### Delete Likes (Un-favorite/Un-like)

```shell
./unlike.sh <like_id>
```

Batch delete likes listed in `likes.*.jsonl` produced above:

```shell
cat likes.*.jsonl | jq --raw-output '.id_str' | parallel -k --delay 0.1 --bar -j 1 --resume --joblog +unlike.joblog ./unlike.sh
```

If you still see Likes on your Profile page:

1. Remove `likes.*.jsonl` from this folder
2. Remove `unlike.joblog` from this folder
3. Download likes again
4. Run batch deletion script

## Followers and Followings

### Download Followers

```shell
./download-followers.sh <screen_name>
```

=> `followers.*.jsonl`

### Download List of Users I'm Following

```shell
./download-followings.sh <screen_name>
```

=> `followings.*.jsonl`

### Find Followers that I am not Following

Given `followers.*.jsonl` and `followings.*.jsonl` exist:

```shell
./find-strangers.sh > strangers.jsonl
```

=> `strangers.jsonl`

### Force someone to unfollow me

```shell
./kickout-follower.sh <screen_name>
```

In a batch:

```shell
cat strangers.jsonl | jq --raw-output '.screen_name' | parallel -k --delay 0.1 --bar --resume --joblog +kickout.joblog ./kickout-follower.sh
```

## License

MIT License. See [LICENSE](./LICENSE).
