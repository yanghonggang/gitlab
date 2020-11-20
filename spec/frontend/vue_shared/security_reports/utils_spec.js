import { extractSecurityReportArtifacts } from '~/vue_shared/security_reports/utils';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
} from '~/vue_shared/security_reports/constants';
import { reportTypeDownloadPathsQueryResponse } from './mock_data';

describe('extractSecurityReportArtifacts', () => {
  const sastArtifacts = [
    {
      name: 'bandit-sast',
      reportType: REPORT_TYPE_SAST,
      path: '/gitlab-org/secrets-detection-test/-/jobs/1400/artifacts/download?file_type=sast',
    },
    {
      name: 'eslint-sast',
      reportType: REPORT_TYPE_SAST,
      path: '/gitlab-org/secrets-detection-test/-/jobs/1401/artifacts/download?file_type=sast',
    },
  ];
  const secretDetectionArtifacts = [
    {
      name: 'secret_detection',
      reportType: REPORT_TYPE_SECRET_DETECTION,
      path:
        '/gitlab-org/secrets-detection-test/-/jobs/1399/artifacts/download?file_type=secret_detection',
    },
  ];

  it.each`
    reportTypes                                         | expectedArtifacts
    ${[]}                                               | ${[]}
    ${['foo']}                                          | ${[]}
    ${[REPORT_TYPE_SAST]}                               | ${sastArtifacts}
    ${[REPORT_TYPE_SECRET_DETECTION]}                   | ${secretDetectionArtifacts}
    ${[REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION]} | ${[...secretDetectionArtifacts, ...sastArtifacts]}
  `(
    'returns the expected artifacts given report types $reportTypes',
    ({ reportTypes, expectedArtifacts }) => {
      expect(
        extractSecurityReportArtifacts(reportTypes, reportTypeDownloadPathsQueryResponse),
      ).toEqual(expectedArtifacts);
    },
  );
});
