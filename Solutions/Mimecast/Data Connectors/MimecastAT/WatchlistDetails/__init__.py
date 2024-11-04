"""Init module for PerformanceDetails."""

import datetime
import logging
import time
import azure.functions as func
from .mimecast_watchlist_details_to_sentinel import MimecastAwarenessWatchlist


def main(mytimer: func.TimerRequest) -> None:
    """Driver method for awareness training performance details."""
    utc_timestamp = (
        datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
    )
    function_start_time = time.time()
    performance_details_obj = MimecastAwarenessWatchlist(function_start_time)
    performance_details_obj.get_awareness_watchlist_details_data_in_sentinel()
    if mytimer.past_due:
        logging.info("The timer is past due!")

    logging.info("Python timer trigger function ran at %s", utc_timestamp)
