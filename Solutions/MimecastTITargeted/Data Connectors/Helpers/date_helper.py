import datetime

from ..Models.Error.errors import ParsingError


class DateHelper:
    """DateHelper class responsible for making Mimecast specific date formats needed in request models."""

    @staticmethod
    def get_utc_time_from_now(days):
        """Generating time by adding days to current UTC time."""
        now = datetime.datetime.utcnow()
        offset_time = now + datetime.timedelta(days=days)
        return offset_time.strftime("%Y-%m-%dT%H:%M:%SZ")

    @staticmethod
    def get_utc_time_in_past(days):
        """Generating time by subtracting days from current UTC time."""
        now = datetime.datetime.utcnow()
        offset_time = now - datetime.timedelta(days=days)
        offset_time = offset_time.replace(tzinfo=datetime.timezone.utc)
        return offset_time.strftime("%Y-%m-%dT%H:%M:%S%z")

    @staticmethod
    def convert_from_mimecast_format(datetime_str):
        try:
            datetime_obj = datetime.datetime.strptime(datetime_str, '%Y-%m-%dT%H:%M:%S%z')
        except ValueError:
            try:
                datetime_obj = datetime.datetime.strptime(datetime_str, '%Y-%m-%dT%H:%M:%S.%fZ')
            except ValueError:
                raise ParsingError(f'Unknown time format: {datetime_str}')

        converted_datetime = datetime_obj.astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        return converted_datetime

    @staticmethod
    def convert_to_mimecast_format(datetime_str, current_format):
        converted_datetime = datetime.datetime.strptime(datetime_str, current_format)
        converted_datetime = converted_datetime.astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S%z")
        return converted_datetime
