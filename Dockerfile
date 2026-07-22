# csvq — reproducible container image.
# Default awk in debian-slim is mawk; diffutils provides cmp/diff for the tests.
FROM debian:12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends gawk diffutils findutils \
 && rm -rf /var/lib/apt/lists/*

# Use gawk explicitly so behaviour does not depend on the awk alternative.
ENV CSVQ_AWK=gawk

WORKDIR /app
COPY . .
RUN chmod +x csvq.sh tests/run_tests.sh tests/framework.sh

# Run the offline test suite at build time to fail fast on a broken image.
RUN tests/run_tests.sh

ENTRYPOINT ["/app/csvq.sh"]
CMD ["help"]
