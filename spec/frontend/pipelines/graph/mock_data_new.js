export const mockPipelineResponse = {
  data: {
    project: {
      __typename: 'Project',
      pipeline: {
        __typename: 'Pipeline',
        id: '22',
        stages: {
          __typename: 'CiStageConnection',
          nodes: [
            {
              __typename: 'CiStage',
              name: 'build',
              status: {
                __typename: 'DetailedStatus',
                action: null
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1482',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1482/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: []
                          }
                        }
                      ]
                    }
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_b',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_b',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1515',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1515/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: []
                          }
                        }
                      ]
                    }
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_c',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_c',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1484',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1484/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: []
                          }
                        }
                      ]
                    }
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'build_d',
                    size: 3,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'build_d 1/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1485',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1485/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: []
                          }
                        },
                        {
                          __typename: 'CiJob',
                          name: 'build_d 2/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1486',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1486/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: []
                          }
                        },
                        {
                          __typename: 'CiJob',
                          name: 'build_d 3/3',
                          scheduledAt: null,
                          status: {
                            __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1487',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1487/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: []
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            },
           {
              __typename: 'CiStage',
              name: 'test',
              status: {
                __typename: 'DetailedStatus',
                action: null
              },
              groups: {
                __typename: 'CiGroupConnection',
                nodes: [
                  {
                    __typename: 'CiGroup',
                    name: 'test_a',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'test_a',
                          scheduledAt: null,
                          status: {
                              __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1514',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1514/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiJob',
                                name: 'build_c'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_b'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl'
                              }
                            ]
                          }
                        }
                      ]
                    }
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'test_b',
                    size: 2,
                    status: {
                      __typename: 'DetailedStatus',
                      label: 'passed',
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'test_b 1/2',
                          scheduledAt: null,
                          status: {
                              __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1489',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              'buttonTitle': 'Retry this job',
                              'icon': 'retry',
                              'path': '/root/abcd-dag/-/jobs/1489/retry',
                              'title': 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiJob',
                                name: 'build_d 3/3'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_d 2/3'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_d 1/3'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_b'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl'
                              }
                            ]
                          }
                        },
                        {
                          __typename: 'CiJob',
                          name: 'test_b 2/2',
                          scheduledAt: null,
                          status: {
                              __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: 'passed',
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/jobs/1490',
                            group: 'success',
                            action: {
                              __typename: 'StatusAction',
                              buttonTitle: 'Retry this job',
                              icon: 'retry',
                              path: '/root/abcd-dag/-/jobs/1490/retry',
                              title: 'Retry'
                            }
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiJob',
                                name: 'build_d 3/3'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_d 2/3'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_d 1/3'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_b'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl'
                              }
                            ]
                          }
                        }
                      ]
                    }
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'test_c',
                    size: 1,
                    status: {
                        __typename: 'DetailedStatus',
                      label: null,
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'test_c',
                          scheduledAt: null,
                          status: {
                              __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: null,
                            hasDetails: true,
                            detailsPath: '/root/kinder-pipe/-/pipelines/154',
                            group: 'success',
                            action: null
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiJob',
                                name: 'build_c'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_b'
                              },
                              {
                                __typename: 'CiJob',
                                name: 'build_a_nlfjkdnlvskfnksvjknlfdjvlvnjdkjdf_nvjkenjkrlngjeknjkl'
                              }
                            ]
                          }
                        }
                      ]
                    }
                  },
                  {
                    __typename: 'CiGroup',
                    name: 'test_d',
                    size: 1,
                    status: {
                      __typename: 'DetailedStatus',
                      label: null,
                      group: 'success',
                      icon: 'status_success'
                    },
                    jobs: {
                      __typename: 'CiJobConnection',
                      nodes: [
                        {
                          __typename: 'CiJob',
                          name: 'test_d',
                          scheduledAt: null,
                          status: {
                              __typename: 'DetailedStatus',
                            icon: 'status_success',
                            tooltip: null,
                            hasDetails: true,
                            detailsPath: '/root/abcd-dag/-/pipelines/153',
                            group: 'success',
                            action: null
                          },
                          needs: {
                            __typename: 'CiJobConnection',
                            nodes: [
                              {
                                __typename: 'CiJob',
                                name: 'build_b'
                              }
                            ]
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}
