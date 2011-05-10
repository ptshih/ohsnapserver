# File config/initializers/constants.rb

API_VERSION = 'v1'

OHSNAP_SECRET = Digest::SHA256.hexdigest("omgwtfbbqflylikeag6")

S3_BASE_URL = "http://s3.amazonaws.com/scrapboard/snaps"