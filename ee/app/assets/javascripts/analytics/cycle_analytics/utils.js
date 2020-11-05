import { isNumber } from 'lodash';
import dateFormat from 'dateformat';
import { s__, sprintf } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import httpStatus from '~/lib/utils/http_status';
import { convertToSnakeCase, slugify } from '~/lib/utils/text_utility';
import { hideFlash, deprecatedCreateFlash as createFlash } from '~/flash';
import {
  newDate,
  dayAfter,
  secondsToDays,
  getDatesInRange,
  parseSeconds,
} from '~/lib/utils/datetime_utility';
import { dateFormats } from '../shared/constants';
import { toYmd } from '../shared/utils';

const EVENT_TYPE_LABEL = 'label';
const ERROR_NAME_RESERVED = 'is reserved';

export const removeFlash = (type = 'alert') => {
  const flashEl = document.querySelector(`.flash-${type}`);
  if (flashEl) {
    hideFlash(flashEl);
  }
};

export const toggleSelectedLabel = ({ selectedLabelIds = [], value = null }) => {
  if (!value) return selectedLabelIds;
  return selectedLabelIds.includes(value)
    ? selectedLabelIds.filter(v => v !== value)
    : [...selectedLabelIds, value];
};

export const isStartEvent = ev => Boolean(ev) && Boolean(ev.canBeStartEvent) && ev.canBeStartEvent;

export const eventToOption = (obj = null) => {
  if (!obj || (!obj.text && !obj.identifier)) return null;
  const { name: text = '', identifier: value = null } = obj;
  return { text, value };
};

export const getAllowedEndEvents = (events = [], targetIdentifier = null) => {
  if (!targetIdentifier || !events.length) return [];
  const st = events.find(({ identifier }) => identifier === targetIdentifier);
  return st && st.allowedEndEvents ? st.allowedEndEvents : [];
};

export const eventsByIdentifier = (events = [], targetIdentifier = []) => {
  if (!targetIdentifier || !targetIdentifier.length || !events.length) return [];
  return events.filter(({ identifier = '' }) => targetIdentifier.includes(identifier));
};

export const isLabelEvent = (labelEvents = [], ev = null) =>
  Boolean(ev) && labelEvents.length && labelEvents.includes(ev);

export const getLabelEventsIdentifiers = (events = []) =>
  events.filter(ev => ev.type && ev.type === EVENT_TYPE_LABEL).map(i => i.identifier);

/**
 * Checks if the specified stage is in memory or persisted to storage based on the id
 *
 * Default value stream analytics stages are initially stored in memory, when they are first
 * created the id for the stage is the name of the stage in lowercase. This string id
 * is used to fetch stage data (events, median calculation)
 *
 * When either a custom stage is created or an edit is made to a default stage then the
 * default stages get persisted to storage and will have a numeric id. The new numeric
 * id should then be used to access stage data
 *
 */
export const isPersistedStage = ({ custom, id }) => custom || isNumber(id);

/**
 * Returns the the correct slug to use for a stage
 * default stages use the snakecased title of the stage, while custom
 * stages will have a numeric id
 *
 * @param {Object} obj
 * @param {string} obj.title - title of the stage
 * @param {number} obj.id - numerical object id available for custom stages
 * @param {boolean} obj.custom - boolean flag indicating a custom stage
 * @returns {(number|string)} Returns a numerical id for customs stages and string for default stages
 */
const stageUrlSlug = ({ id, title, custom = false }) => {
  if (custom) return id;

  return convertToSnakeCase(title);
};

export const transformRawStages = (stages = []) =>
  stages.map(({ id, title, name = '', custom = false, ...rest }) => ({
    ...convertObjectPropsToCamelCase(rest, { deep: true }),
    id,
    title,
    custom,
    slug: isPersistedStage({ custom, id }) ? id : stageUrlSlug({ custom, id, title }),
    // the name field is used to create a stage, but the get request returns title
    name: name.length ? name : title,
  }));

export const transformRawTasksByTypeData = (data = []) => {
  if (!data.length) return [];
  return data.map(d => convertObjectPropsToCamelCase(d, { deep: true }));
};

/**
 * Takes the duration data for selected stages, transforms the date values and returns
 * the data in a flattened array
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    slug: 'issue',
 *    selected: true,
 *    data: [
 *      {
 *        'duration_in_seconds': 1234,
 *        'finished_at': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then transformed and flattened into the following format;
 * [
 *  {
 *    'duration_in_seconds': 1234,
 *    'finished_at': '2019-09-02'
 *  },
 *  ...
 * ]
 *
 * @param {Array} data - The duration data for selected stages
 * @returns {Array} An array with each item being an object containing the duration_in_seconds and finished_at values for an event
 */
export const flattenDurationChartData = data =>
  data
    .map(stage =>
      stage.data.map(event => {
        const date = new Date(event.finished_at);
        return {
          ...event,
          finished_at: dateFormat(date, dateFormats.isoDate),
        };
      }),
    )
    .flat();

/**
 * Takes the duration data for selected stages, groups the data by day and calculates the total duration
 * per day.
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    slug: 'issue',
 *    selected: true,
 *    data: [
 *      {
 *        'duration_in_seconds': 1234,
 *        'finished_at': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then computed and transformed into a format that can be passed to the chart:
 * [
 *  ['2019-09-02', 7, '2019-09-02'],
 *  ['2019-09-03', 10, '2019-09-03'],
 *  ['2019-09-04', 8, '2019-09-04'],
 *  ...
 * ]
 *
 * In the data above, each array i represents a point in the scatterplot with the following data:
 * i[0] = date, displayed on x axis
 * i[1] = metric, displayed on y axis
 * i[2] = date, used in the tooltip
 *
 * @param {Array} data - The duration data for selected stages
 * @param {Date} startDate - The globally selected cycle analytics start date
 * @param {Date} endDate - The globally selected cycle analytics end date
 * @returns {Array} An array with each item being another arry of three items (plottable date, computed total, tooltip display date)
 */
export const getDurationChartData = (data, startDate, endDate) => {
  const flattenedData = flattenDurationChartData(data);
  const eventData = [];

  for (
    let currentDate = newDate(startDate);
    currentDate <= endDate;
    currentDate = dayAfter(currentDate)
  ) {
    const currentISODate = dateFormat(newDate(currentDate), dateFormats.isoDate);
    const valuesForDay = flattenedData.filter(object => object.finished_at === currentISODate);
    const summedData = valuesForDay.reduce((total, value) => total + value.duration_in_seconds, 0);
    const summedDataInDays = secondsToDays(summedData);

    if (summedDataInDays) eventData.push([currentISODate, summedDataInDays, currentISODate]);
  }

  return eventData;
};

export const orderByDate = (a, b, dateFmt = datetime => new Date(datetime).getTime()) =>
  dateFmt(a) - dateFmt(b);

/**
 * Takes a dictionary of dates and the associated value, sorts them and returns just the value
 *
 * @param {Object.<Date, number>} series - Key value pair of dates and the value for that date
 * @returns {number[]} The values of each key value pair
 */
export const flattenTaskByTypeSeries = (series = {}) =>
  Object.entries(series)
    .sort((a, b) => orderByDate(a[0], b[0]))
    .map(dataSet => dataSet[1]);

/**
 * @typedef {Object} RawTasksByTypeData
 * @property {Object} label - Raw data for a group label
 * @property {Array} series - Array of arrays with date and associated value ie [ ['2020-01-01', 10],['2020-01-02', 10] ]

 * @typedef {Object} TransformedTasksByTypeData
 * @property {Array} groupBy - The list of dates for the range of data in each data series
 * @property {Array} data - An array of the data values for each series
 * @property {Array} seriesNames - Names of the series to be charted ie label names
 */

/**
 * Takes the raw tasks by type data and generates an array of data points,
 * an array of data series and an array of data labels for the given time period.
 *
 * Currently the data is transformed to support use in a stacked column chart:
 * https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/charts-stacked-column-chart--stacked
 *
 * @param {Object} obj
 * @param {RawTasksByTypeData[]} obj.data - array of raw data, each element contains a label and series
 * @param {Date} obj.startDate - start date in ISO date format
 * @param {Date} obj.endDate - end date in ISO date format
 *
 * @returns {TransformedTasksByTypeData} The transformed data ready for use in charts
 */
export const getTasksByTypeData = ({ data = [], startDate = null, endDate = null }) => {
  if (!startDate || !endDate || !data.length) {
    return {
      groupBy: [],
      data: [],
    };
  }

  const groupBy = getDatesInRange(startDate, endDate, toYmd).sort(orderByDate);
  const zeroValuesForEachDataPoint = groupBy.reduce(
    (acc, date) => ({
      ...acc,
      [date]: 0,
    }),
    {},
  );

  const transformed = data.reduce(
    (acc, curr) => {
      const {
        label: { title: name },
        series,
      } = curr;
      acc.data = [
        ...acc.data,
        {
          name,
          // adds 0 values for each data point and overrides with data from the series
          data: flattenTaskByTypeSeries({
            ...zeroValuesForEachDataPoint,
            ...Object.fromEntries(series),
          }),
        },
      ];
      return acc;
    },
    {
      data: [],
      seriesNames: [],
    },
  );

  return {
    ...transformed,
    groupBy,
  };
};

const buildDataError = ({ status = httpStatus.INTERNAL_SERVER_ERROR, error }) => {
  const err = new Error(error);
  err.errorCode = status;
  return err;
};

/**
 * Flashes an error message if the status code is not 200
 *
 * @param {Object} error - Axios error object
 * @param {String} errorMessage - Error message to display
 */
export const flashErrorIfStatusNotOk = ({ error, message }) => {
  if (error?.errorCode !== httpStatus.OK) {
    createFlash(message);
  }
};

/**
 * Data errors can occur when DB queries for analytics data time out
 * The server will respond with a status `200` success and include the
 * relevant error in the response body
 *
 * @param {Object} Response - Axios ajax response
 * @returns {Object} Returns the axios ajax response
 */
export const checkForDataError = response => {
  const { data, status } = response;
  if (data?.error) {
    throw buildDataError({ status, error: data.error });
  }
  return response;
};

export const throwIfUserForbidden = error => {
  if (error?.response?.status === httpStatus.FORBIDDEN) {
    throw error;
  }
};

export const isStageNameExistsError = ({ status, errors }) =>
  status === httpStatus.UNPROCESSABLE_ENTITY && errors?.name?.includes(ERROR_NAME_RESERVED);

/**
 * Takes the stages and median data, combined with the selected stage, to build an
 * array which is formatted to proivde the data required for the path navigation.
 *
 * @param {Array} stages - The stages available to the group / project
 * @param {Object} medians - The median values for the stages available to the group / project
 * @param {Object} selectedStage - The currently selected stage
 * @returns {Array} An array of stages formatted with data required for the path navigation
 */
export const transformStagesForPathNavigation = ({ stages, medians, selectedStage }) => {
  const formattedStages = stages.map(stage => {
    const { days } = parseSeconds(medians[stage.id], {
      daysPerWeek: 7,
      hoursPerDay: 24,
      limitToDays: true,
    });

    return {
      ...stage,
      metric: days ? sprintf(s__('ValueStreamAnalytics|%{days}d'), { days }) : null,
      selected: stage.title === selectedStage.title,
      title: stage.title,
      icon: null,
    };
  });

  return formattedStages;
};

/**
 * @typedef {Object} MetricData
 * @property {String} title - Title of the metric measured
 * @property {String} value - String representing the decimal point value, e.g '1.5'
 * @property {String} [unit] - String representing the decimal point value, e.g '1.5'
 *
 * @typedef {Object} TransformedMetricData
 * @property {String} label - Title of the metric measured
 * @property {String} value - String representing the decimal point value, e.g '1.5'
 * @property {String} key - Slugified string based on the 'title'
 * @property {String} [tooltipText] - String to display for aa tooltip
 * @property {String} [unit] - String representing the decimal point value, e.g '1.5'
 */

/**
 * Prepares metric data to be rendered in the metric_card component
 *
 * @param {MetricData[]} data - The metric data to be rendered
 * @param {Object} [tooltipText] - Key value pair of strings to display in the tooltip
 * @returns {TransformedMetricData[]} An array of metrics ready to render in the metric_card
 */

export const prepareTimeMetricsData = (data = [], tooltipText = {}) =>
  data.map(({ title: label, ...rest }) => {
    const key = slugify(label);
    return {
      ...rest,
      label,
      key,
      tooltipText: tooltipText[key] || '',
    };
  });
