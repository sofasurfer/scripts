import sys
import argparse
import tweepy


# == OAuth Authentication ==
#
# This mode of authentication is the new preferred way
# of authenticating with Twitter.

# The message to post

parser = argparse.ArgumentParser()

parser = argparse.ArgumentParser()
parser.add_argument("message", help="echo the string you use here")
args = parser.parse_args()


# The consumer keys can be found on your application's Details
# page located at https://dev.twitter.com/apps (under "OAuth settings")
consumer_key="3w8NRtQEk6zIE956zD20vw"
consumer_secret="OzK1V2O36pDaDsW4kH2F8jsZZSRNVaEvFsgeQ3MX24Y"

# The access tokens can be found on your applications's Details
# page located at https://dev.twitter.com/apps (located 
# under "Your access token")
access_token="739609950-DcmxADTitmAmIKdrBF4GakIkjU9LrmvgzLYDvYOF"
access_token_secret="95j2Gr9YMUNED9XTAtMIWDi3WVQ3bE3tEl865drUY"

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)

api = tweepy.API(auth)

# If the authentication was successful, you should
# see the name of the account print out

print api.me().name

# If the application settings are set for "Read and Write" then
# this line should tweet out the message to your account's 
# timeline. The "Read and Write" setting is on https://dev.twitter.com/apps
api.update_status( args.message )
