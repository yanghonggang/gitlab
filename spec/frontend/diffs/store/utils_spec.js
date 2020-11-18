import { clone } from 'lodash';
import * as utils from '~/diffs/store/utils';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
  LEGACY_DIFF_NOTE_TYPE,
  DIFF_NOTE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  MATCH_LINE_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
} from '~/diffs/constants';
import { MERGE_REQUEST_NOTEABLE_TYPE } from '~/notes/constants';
import diffFileMockData from '../mock_data/diff_file';
import { diffMetadata } from '../mock_data/diff_metadata';
import { noteableDataMock } from '../../notes/mock_data';

const getDiffFileMock = () => JSON.parse(JSON.stringify(diffFileMockData));
const getDiffMetadataMock = () => JSON.parse(JSON.stringify(diffMetadata));

function extractLinesFromFile(file) {
  const unpackedParallel = file.parallel_diff_lines
    .flatMap(({ left, right }) => [left, right])
    .filter(Boolean);

  return [...file.highlighted_diff_lines, ...unpackedParallel];
}

describe('DiffsStoreUtils', () => {
  describe('findDiffFile', () => {
    const files = [{ file_hash: 1, name: 'one' }];

    it('should return correct file', () => {
      expect(utils.findDiffFile(files, 1).name).toEqual('one');
      expect(utils.findDiffFile(files, 2)).toBeUndefined();
    });
  });

  describe('getReversePosition', () => {
    it('should return correct line position name', () => {
      expect(utils.getReversePosition(LINE_POSITION_RIGHT)).toEqual(LINE_POSITION_LEFT);
      expect(utils.getReversePosition(LINE_POSITION_LEFT)).toEqual(LINE_POSITION_RIGHT);
    });
  });

  describe('findIndexInInlineLines and findIndexInParallelLines', () => {
    const expectSet = (method, lines, invalidLines) => {
      expect(method(lines, { oldLineNumber: 3, newLineNumber: 5 })).toEqual(4);
      expect(method(invalidLines || lines, { oldLineNumber: 32, newLineNumber: 53 })).toEqual(-1);
    };

    describe('findIndexInInlineLines', () => {
      it('should return correct index for given line numbers', () => {
        expectSet(utils.findIndexInInlineLines, getDiffFileMock().highlighted_diff_lines);
      });
    });

    describe('findIndexInParallelLines', () => {
      it('should return correct index for given line numbers', () => {
        expectSet(utils.findIndexInParallelLines, getDiffFileMock().parallel_diff_lines, []);
      });
    });
  });

  describe('getPreviousLineIndex', () => {
    [
      { diffViewType: INLINE_DIFF_VIEW_TYPE, file: { parallel_diff_lines: [] } },
      { diffViewType: PARALLEL_DIFF_VIEW_TYPE, file: { highlighted_diff_lines: [] } },
    ].forEach(({ diffViewType, file }) => {
      describe(`with diffViewType (${diffViewType}) in split diffs`, () => {
        let diffFile;

        beforeEach(() => {
          diffFile = { ...clone(diffFileMockData), ...file };
        });

        it('should return the correct previous line number', () => {
          const emptyLines =
            diffViewType === INLINE_DIFF_VIEW_TYPE
              ? diffFile.parallel_diff_lines
              : diffFile.highlighted_diff_lines;

          // This expectation asserts that we cannot possibly be using the opposite view type lines in the next expectation
          expect(emptyLines.length).toBe(0);
          expect(
            utils.getPreviousLineIndex(diffViewType, diffFile, {
              oldLineNumber: 3,
              newLineNumber: 5,
            }),
          ).toBe(4);
        });
      });
    });
  });

  describe('removeMatchLine', () => {
    it('should remove match line properly by regarding the bottom parameter', () => {
      const diffFile = getDiffFileMock();
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const inlineIndex = utils.findIndexInInlineLines(
        diffFile.highlighted_diff_lines,
        lineNumbers,
      );
      const parallelIndex = utils.findIndexInParallelLines(
        diffFile.parallel_diff_lines,
        lineNumbers,
      );
      const atInlineIndex = diffFile.highlighted_diff_lines[inlineIndex];
      const atParallelIndex = diffFile.parallel_diff_lines[parallelIndex];

      utils.removeMatchLine(diffFile, lineNumbers, false);

      expect(diffFile.highlighted_diff_lines[inlineIndex]).not.toEqual(atInlineIndex);
      expect(diffFile.parallel_diff_lines[parallelIndex]).not.toEqual(atParallelIndex);

      utils.removeMatchLine(diffFile, lineNumbers, true);

      expect(diffFile.highlighted_diff_lines[inlineIndex + 1]).not.toEqual(atInlineIndex);
      expect(diffFile.parallel_diff_lines[parallelIndex + 1]).not.toEqual(atParallelIndex);
    });
  });

  describe('addContextLines', () => {
    [INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE].forEach(diffViewType => {
      it(`should add context lines for ${diffViewType}`, () => {
        const diffFile = getDiffFileMock();
        const inlineLines = diffFile.highlighted_diff_lines;
        const parallelLines = diffFile.parallel_diff_lines;
        const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
        const contextLines = [{ lineNumber: 42, line_code: '123' }];
        const options = { inlineLines, parallelLines, contextLines, lineNumbers, diffViewType };
        const inlineIndex = utils.findIndexInInlineLines(inlineLines, lineNumbers);
        const parallelIndex = utils.findIndexInParallelLines(parallelLines, lineNumbers);
        const normalizedParallelLine = {
          left: options.contextLines[0],
          right: options.contextLines[0],
          line_code: '123',
        };

        utils.addContextLines(options);

        if (diffViewType === INLINE_DIFF_VIEW_TYPE) {
          expect(inlineLines[inlineIndex]).toEqual(contextLines[0]);
        } else {
          expect(parallelLines[parallelIndex]).toEqual(normalizedParallelLine);
        }
      });

      it(`should add context lines properly with bottom parameter for ${diffViewType}`, () => {
        const diffFile = getDiffFileMock();
        const inlineLines = diffFile.highlighted_diff_lines;
        const parallelLines = diffFile.parallel_diff_lines;
        const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
        const contextLines = [{ lineNumber: 42, line_code: '123' }];
        const options = {
          inlineLines,
          parallelLines,
          contextLines,
          lineNumbers,
          bottom: true,
          diffViewType,
        };
        const normalizedParallelLine = {
          left: options.contextLines[0],
          right: options.contextLines[0],
          line_code: '123',
        };

        utils.addContextLines(options);

        if (diffViewType === INLINE_DIFF_VIEW_TYPE) {
          expect(inlineLines[inlineLines.length - 1]).toEqual(contextLines[0]);
        } else {
          expect(parallelLines[parallelLines.length - 1]).toEqual(normalizedParallelLine);
        }
      });
    });
  });

  describe('getNoteFormData', () => {
    it('should properly create note form data', () => {
      const diffFile = getDiffFileMock();
      noteableDataMock.targetType = MERGE_REQUEST_NOTEABLE_TYPE;

      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          line_code: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          meta_data: null,
          new_line: 3,
          old_line: 1,
        },
        diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        linePosition: LINE_POSITION_LEFT,
        lineRange: { start_line_code: 'abc_1_1', end_line_code: 'abc_2_2' },
      };

      const position = JSON.stringify({
        base_sha: diffFile.diff_refs.base_sha,
        start_sha: diffFile.diff_refs.start_sha,
        head_sha: diffFile.diff_refs.head_sha,
        old_path: diffFile.old_path,
        new_path: diffFile.new_path,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.old_line,
        new_line: options.noteTargetLine.new_line,
        line_range: options.lineRange,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: diffFile.diff_refs.head_sha,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        return_discussion: true,
        note: {
          noteable_type: options.noteableType,
          noteable_id: options.noteableData.id,
          commit_id: undefined,
          type: DIFF_NOTE_TYPE,
          line_code: options.noteTargetLine.line_code,
          note: options.note,
          position,
        },
      };

      expect(utils.getNoteFormData(options)).toEqual({
        endpoint: options.noteableData.create_note_path,
        data: postData,
      });
    });

    it('should create legacy note form data', () => {
      const diffFile = getDiffFileMock();
      delete diffFile.diff_refs.start_sha;
      delete diffFile.diff_refs.head_sha;

      noteableDataMock.targetType = MERGE_REQUEST_NOTEABLE_TYPE;

      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          line_code: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          meta_data: null,
          new_line: 3,
          old_line: 1,
        },
        diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        linePosition: LINE_POSITION_LEFT,
      };

      const position = JSON.stringify({
        base_sha: diffFile.diff_refs.base_sha,
        start_sha: undefined,
        head_sha: undefined,
        old_path: diffFile.old_path,
        new_path: diffFile.new_path,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.old_line,
        new_line: options.noteTargetLine.new_line,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: undefined,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        return_discussion: true,
        note: {
          noteable_type: options.noteableType,
          noteable_id: options.noteableData.id,
          commit_id: undefined,
          type: LEGACY_DIFF_NOTE_TYPE,
          line_code: options.noteTargetLine.line_code,
          note: options.note,
          position,
        },
      };

      expect(utils.getNoteFormData(options)).toEqual({
        endpoint: options.noteableData.create_note_path,
        data: postData,
      });
    });
  });

  describe('addLineReferences', () => {
    const lineNumbers = { oldLineNumber: 3, newLineNumber: 4 };

    it('should add correct line references when bottom set to true', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers, true);

      expect(linesWithReferences[0].old_line).toEqual(lineNumbers.oldLineNumber + 1);
      expect(linesWithReferences[0].new_line).toEqual(lineNumbers.newLineNumber + 1);
      expect(linesWithReferences[1].meta_data.old_pos).toEqual(4);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(5);
    });

    it('should add correct line references when bottom falsy', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }, { type: null }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers);

      expect(linesWithReferences[0].old_line).toEqual(0);
      expect(linesWithReferences[0].new_line).toEqual(1);
      expect(linesWithReferences[1].meta_data.old_pos).toEqual(2);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(3);
    });

    it('should add correct line references when isExpandDown is true', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers, false, true, {
        old_line: 10,
        new_line: 11,
      });

      expect(linesWithReferences[1].meta_data.old_pos).toEqual(10);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(11);
    });
  });

  describe('trimFirstCharOfLineContent', () => {
    it('trims the line when it starts with a space', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: ' diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('trims the line when it starts with a +', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: '+diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('trims the line when it starts with a -', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: '-diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('does not trims the line when it starts with a letter', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: 'diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('does not modify the provided object', () => {
      const lineObj = {
        rich_text: ' diff',
      };

      utils.trimFirstCharOfLineContent(lineObj);

      expect(lineObj).toEqual({ rich_text: ' diff' });
    });

    it('handles a undefined or null parameter', () => {
      expect(utils.trimFirstCharOfLineContent()).toEqual({});
    });
  });

  describe('prepareLineForRenamedFile', () => {
    const diffFile = {
      file_hash: 'file-hash',
    };
    const lineIndex = 4;
    const sourceLine = {
      foo: 'test',
      rich_text: ' <p>rich</p>', // Note the leading space
    };
    const correctLine = {
      foo: 'test',
      line_code: 'file-hash_5_5',
      old_line: 5,
      new_line: 5,
      rich_text: '<p>rich</p>', // Note no leading space
      discussionsExpanded: true,
      discussions: [],
      hasForm: false,
      text: undefined,
      alreadyPrepared: true,
    };
    let preppedLine;

    beforeEach(() => {
      preppedLine = utils.prepareLineForRenamedFile({
        diffViewType: INLINE_DIFF_VIEW_TYPE,
        line: sourceLine,
        index: lineIndex,
        diffFile,
      });
    });

    it('copies over the original line object to the new prepared line', () => {
      expect(preppedLine).toEqual(
        expect.objectContaining({
          foo: correctLine.foo,
          rich_text: correctLine.rich_text,
        }),
      );
    });

    it('correctly sets the old and new lines, plus a line code', () => {
      expect(preppedLine.old_line).toEqual(correctLine.old_line);
      expect(preppedLine.new_line).toEqual(correctLine.new_line);
      expect(preppedLine.line_code).toEqual(correctLine.line_code);
    });

    it('returns a single object with the correct structure for `inline` lines', () => {
      expect(preppedLine).toEqual(correctLine);
    });

    it('returns a nested object with "left" and "right" lines + the line code for `parallel` lines', () => {
      preppedLine = utils.prepareLineForRenamedFile({
        diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        line: sourceLine,
        index: lineIndex,
        diffFile,
      });

      expect(Object.keys(preppedLine)).toEqual(['left', 'right', 'line_code']);
      expect(preppedLine.left).toEqual(correctLine);
      expect(preppedLine.right).toEqual(correctLine);
      expect(preppedLine.line_code).toEqual(correctLine.line_code);
    });

    it.each`
      brokenSymlink
      ${false}
      ${{}}
      ${'anything except `false`'}
    `(
      "properly assigns each line's `commentsDisabled` as the same value as the parent file's `brokenSymlink` value (`$brokenSymlink`)",
      ({ brokenSymlink }) => {
        preppedLine = utils.prepareLineForRenamedFile({
          diffViewType: INLINE_DIFF_VIEW_TYPE,
          line: sourceLine,
          index: lineIndex,
          diffFile: {
            ...diffFile,
            brokenSymlink,
          },
        });

        expect(preppedLine.commentsDisabled).toStrictEqual(brokenSymlink);
      },
    );
  });

  describe('prepareDiffData', () => {
    describe('for regular diff files', () => {
      let mock;
      let preparedDiff;
      let splitInlineDiff;
      let splitParallelDiff;
      let completedDiff;

      beforeEach(() => {
        mock = getDiffFileMock();

        preparedDiff = { diff_files: [mock] };
        splitInlineDiff = {
          diff_files: [{ ...mock, parallel_diff_lines: undefined }],
        };
        splitParallelDiff = {
          diff_files: [{ ...mock, highlighted_diff_lines: undefined }],
        };
        completedDiff = {
          diff_files: [{ ...mock, highlighted_diff_lines: undefined }],
        };

        preparedDiff.diff_files = utils.prepareDiffData(preparedDiff);
        splitInlineDiff.diff_files = utils.prepareDiffData(splitInlineDiff);
        splitParallelDiff.diff_files = utils.prepareDiffData(splitParallelDiff);
        completedDiff.diff_files = utils.prepareDiffData(completedDiff, [mock]);
      });

      it('sets the renderIt and collapsed attribute on files', () => {
        const firstParallelDiffLine = preparedDiff.diff_files[0].parallel_diff_lines[2];

        expect(firstParallelDiffLine.left.discussions.length).toBe(0);
        expect(firstParallelDiffLine.left).not.toHaveAttr('text');
        expect(firstParallelDiffLine.right.discussions.length).toBe(0);
        expect(firstParallelDiffLine.right).not.toHaveAttr('text');
        const firstParallelChar = firstParallelDiffLine.right.rich_text.charAt(0);

        expect(firstParallelChar).not.toBe(' ');
        expect(firstParallelChar).not.toBe('+');
        expect(firstParallelChar).not.toBe('-');

        const checkLine = preparedDiff.diff_files[0].highlighted_diff_lines[0];

        expect(checkLine.discussions.length).toBe(0);
        expect(checkLine).not.toHaveAttr('text');
        const firstChar = checkLine.rich_text.charAt(0);

        expect(firstChar).not.toBe(' ');
        expect(firstChar).not.toBe('+');
        expect(firstChar).not.toBe('-');

        expect(preparedDiff.diff_files[0].renderIt).toBeTruthy();
        expect(preparedDiff.diff_files[0].collapsed).toBeFalsy();
      });

      it('adds line_code to all lines', () => {
        expect(
          preparedDiff.diff_files[0].parallel_diff_lines.filter(line => !line.line_code),
        ).toHaveLength(0);
      });

      it('uses right line code if left has none', () => {
        const firstLine = preparedDiff.diff_files[0].parallel_diff_lines[0];

        expect(firstLine.line_code).toEqual(firstLine.right.line_code);
      });

      it('guarantees an empty array for both diff styles', () => {
        expect(splitInlineDiff.diff_files[0].parallel_diff_lines.length).toEqual(0);
        expect(splitInlineDiff.diff_files[0].highlighted_diff_lines.length).toBeGreaterThan(0);
        expect(splitParallelDiff.diff_files[0].parallel_diff_lines.length).toBeGreaterThan(0);
        expect(splitParallelDiff.diff_files[0].highlighted_diff_lines.length).toEqual(0);
      });

      it('merges existing diff files with newly loaded diff files to ensure split diffs are eventually completed', () => {
        expect(completedDiff.diff_files.length).toEqual(1);
        expect(completedDiff.diff_files[0].parallel_diff_lines.length).toBeGreaterThan(0);
        expect(completedDiff.diff_files[0].highlighted_diff_lines.length).toBeGreaterThan(0);
      });

      it('leaves files in the existing state', () => {
        const priorFiles = [mock];
        const fakeNewFile = {
          ...mock,
          content_sha: 'ABC',
          file_hash: 'DEF',
        };
        const updatedFilesList = utils.prepareDiffData({ diff_files: [fakeNewFile] }, priorFiles);

        expect(updatedFilesList).toEqual([mock, fakeNewFile]);
      });

      it('completes an existing split diff without overwriting existing diffs', () => {
        // The current state has a file that has only loaded inline lines
        const priorFiles = [{ ...mock, parallel_diff_lines: [] }];
        // The next (batch) load loads two files: the other half of that file, and a new file
        const fakeBatch = [
          { ...mock, highlighted_diff_lines: undefined },
          { ...mock, highlighted_diff_lines: undefined, content_sha: 'ABC', file_hash: 'DEF' },
        ];
        const updatedFilesList = utils.prepareDiffData({ diff_files: fakeBatch }, priorFiles);

        expect(updatedFilesList).toEqual([
          mock,
          expect.objectContaining({
            content_sha: 'ABC',
            file_hash: 'DEF',
          }),
        ]);
      });

      it('adds the `.brokenSymlink` property to each diff file', () => {
        preparedDiff.diff_files.forEach(file => {
          expect(file).toEqual(expect.objectContaining({ brokenSymlink: false }));
        });
      });

      it("copies the diff file's `.brokenSymlink` value to each of that file's child lines", () => {
        const lines = [
          ...preparedDiff.diff_files,
          ...splitInlineDiff.diff_files,
          ...splitParallelDiff.diff_files,
          ...completedDiff.diff_files,
        ].flatMap(file => extractLinesFromFile(file));

        lines.forEach(line => {
          expect(line.commentsDisabled).toBe(false);
        });
      });
    });

    describe('for diff metadata', () => {
      let mock;
      let preparedDiffFiles;

      beforeEach(() => {
        mock = getDiffMetadataMock();

        preparedDiffFiles = utils.prepareDiffData(mock);
      });

      it('sets the renderIt and collapsed attribute on files', () => {
        expect(preparedDiffFiles[0].renderIt).toBeTruthy();
        expect(preparedDiffFiles[0].collapsed).toBeFalsy();
      });

      it('guarantees an empty array of lines for both diff styles', () => {
        expect(preparedDiffFiles[0].parallel_diff_lines.length).toEqual(0);
        expect(preparedDiffFiles[0].highlighted_diff_lines.length).toEqual(0);
      });

      it('leaves files in the existing state', () => {
        const fileMock = getDiffFileMock();
        const metaData = getDiffMetadataMock();
        const priorFiles = [fileMock];
        const updatedFilesList = utils.prepareDiffData(metaData, priorFiles);

        expect(updatedFilesList.length).toEqual(2);
        expect(updatedFilesList[0]).toEqual(fileMock);
      });

      it('adds a new file to the file that already exists in state', () => {
        // This is actually buggy behavior:
        // Because the metadata doesn't include a content_sha,
        // the de-duplicator in prepareDiffData doesn't realize it
        // should combine these two.

        // This buggy behavior hasn't caused a defect YET, because
        // `diffs_metadata.json` is only called the first time the
        // diffs app starts up, which is:
        // - after a fresh page load
        // - after you switch to the changes tab *the first time*

        // This test should begin FAILING and can be reversed to check
        // for just a single file when this is implemented:
        // https://gitlab.com/groups/gitlab-org/-/epics/2852#note_304803233

        const fileMock = getDiffFileMock();
        const metaMock = getDiffMetadataMock();
        const priorFiles = [{ ...fileMock }];
        const updatedFilesList = utils.prepareDiffData(metaMock, priorFiles);

        expect(updatedFilesList).toEqual([
          fileMock,
          {
            ...metaMock.diff_files[0],
            highlighted_diff_lines: [],
            parallel_diff_lines: [],
          },
        ]);
      });

      it('adds the `.brokenSymlink` property to each meta diff file', () => {
        preparedDiffFiles.forEach(file => {
          expect(file).toMatchObject({ brokenSymlink: false });
        });
      });
    });
  });

  describe('isDiscussionApplicableToLine', () => {
    const diffPosition = {
      baseSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      headSha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
      newLine: null,
      newPath: '500-lines-4.txt',
      oldLine: 5,
      oldPath: '500-lines-4.txt',
      startSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
    };

    const wrongDiffPosition = {
      baseSha: 'wrong',
      headSha: 'wrong',
      newLine: null,
      newPath: '500-lines-4.txt',
      oldLine: 5,
      oldPath: '500-lines-4.txt',
      startSha: 'wrong',
    };

    const discussions = {
      upToDateDiscussion1: {
        original_position: diffPosition,
        position: wrongDiffPosition,
      },
      outDatedDiscussion1: {
        original_position: wrongDiffPosition,
        position: wrongDiffPosition,
      },
    };

    // When multi line comments are fully implemented `line_code` will be
    // included in all requests. Until then we need to ensure the logic does
    // not change when it is included only in the "comparison" argument.
    const lineRange = { start_line_code: 'abc_1_1', end_line_code: 'abc_1_2' };

    it('returns true when the discussion is up to date', () => {
      expect(
        utils.isDiscussionApplicableToLine({
          discussion: discussions.upToDateDiscussion1,
          diffPosition: { ...diffPosition, line_range: lineRange },
          latestDiff: true,
        }),
      ).toBe(true);
    });

    it('returns false when the discussion is not up to date', () => {
      expect(
        utils.isDiscussionApplicableToLine({
          discussion: discussions.outDatedDiscussion1,
          diffPosition: { ...diffPosition, line_range: lineRange },
          latestDiff: true,
        }),
      ).toBe(false);
    });

    it('returns true when line codes match and discussion does not contain position and is not active', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: false };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            lineCode: 'ABC_1',
            line_range: lineRange,
          },
          latestDiff: true,
        }),
      ).toBe(false);
    });

    it('returns true when line codes match and discussion does not contain position and is active', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: true };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            line_code: 'ABC_1',
            line_range: lineRange,
          },
          latestDiff: true,
        }),
      ).toBe(true);
    });

    it('returns false when not latest diff', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: true };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            lineCode: 'ABC_1',
            line_range: lineRange,
          },
          latestDiff: false,
        }),
      ).toBe(false);
    });
  });

  describe('generateTreeList', () => {
    let files;

    beforeAll(() => {
      files = [
        {
          new_path: 'app/index.js',
          deleted_file: false,
          new_file: false,
          removed_lines: 10,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'app/test/index.js',
          deleted_file: false,
          new_file: true,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'app/test/filepathneedstruncating.js',
          deleted_file: false,
          new_file: true,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'package.json',
          deleted_file: true,
          new_file: false,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
      ];
    });

    it('creates a tree of files', () => {
      const { tree } = utils.generateTreeList(files);

      expect(tree).toEqual([
        {
          key: 'app',
          path: 'app',
          name: 'app',
          type: 'tree',
          tree: [
            {
              addedLines: 0,
              changed: true,
              deleted: false,
              fileHash: 'test',
              key: 'app/index.js',
              name: 'index.js',
              parentPath: 'app/',
              path: 'app/index.js',
              removedLines: 10,
              tempFile: false,
              type: 'blob',
              tree: [],
            },
            {
              key: 'app/test',
              path: 'app/test',
              name: 'test',
              type: 'tree',
              opened: true,
              tree: [
                {
                  addedLines: 0,
                  changed: true,
                  deleted: false,
                  fileHash: 'test',
                  key: 'app/test/index.js',
                  name: 'index.js',
                  parentPath: 'app/test/',
                  path: 'app/test/index.js',
                  removedLines: 0,
                  tempFile: true,
                  type: 'blob',
                  tree: [],
                },
                {
                  addedLines: 0,
                  changed: true,
                  deleted: false,
                  fileHash: 'test',
                  key: 'app/test/filepathneedstruncating.js',
                  name: 'filepathneedstruncating.js',
                  parentPath: 'app/test/',
                  path: 'app/test/filepathneedstruncating.js',
                  removedLines: 0,
                  tempFile: true,
                  type: 'blob',
                  tree: [],
                },
              ],
            },
          ],
          opened: true,
        },
        {
          key: 'package.json',
          parentPath: '/',
          path: 'package.json',
          name: 'package.json',
          type: 'blob',
          changed: true,
          tempFile: false,
          deleted: true,
          fileHash: 'test',
          addedLines: 0,
          removedLines: 0,
          tree: [],
        },
      ]);
    });

    it('creates flat list of blobs & folders', () => {
      const { treeEntries } = utils.generateTreeList(files);

      expect(Object.keys(treeEntries)).toEqual([
        'app',
        'app/index.js',
        'app/test',
        'app/test/index.js',
        'app/test/filepathneedstruncating.js',
        'package.json',
      ]);
    });
  });

  describe('getDiffMode', () => {
    it('returns mode when matched in file', () => {
      expect(
        utils.getDiffMode({
          renamed_file: true,
        }),
      ).toBe('renamed');
    });

    it('returns mode_changed if key has no match', () => {
      expect(
        utils.getDiffMode({
          viewer: { name: 'mode_changed' },
        }),
      ).toBe('mode_changed');
    });

    it('defaults to replaced', () => {
      expect(utils.getDiffMode({})).toBe('replaced');
    });
  });

  describe('getLowestSingleFolder', () => {
    it('returns path and tree of lowest single folder tree', () => {
      const folder = {
        name: 'app',
        type: 'tree',
        tree: [
          {
            name: 'javascripts',
            type: 'tree',
            tree: [
              {
                type: 'blob',
                name: 'index.js',
              },
            ],
          },
        ],
      };
      const { path, treeAcc } = utils.getLowestSingleFolder(folder);

      expect(path).toEqual('app/javascripts');
      expect(treeAcc).toEqual([
        {
          type: 'blob',
          name: 'index.js',
        },
      ]);
    });

    it('returns passed in folders path & tree when more than tree exists', () => {
      const folder = {
        name: 'app',
        type: 'tree',
        tree: [
          {
            name: 'spec',
            type: 'blob',
            tree: [],
          },
        ],
      };
      const { path, treeAcc } = utils.getLowestSingleFolder(folder);

      expect(path).toEqual('app');
      expect(treeAcc).toBeNull();
    });
  });

  describe('flattenTree', () => {
    it('returns flattened directory structure', () => {
      const tree = [
        {
          type: 'tree',
          name: 'app',
          tree: [
            {
              type: 'tree',
              name: 'javascripts',
              tree: [
                {
                  type: 'blob',
                  name: 'index.js',
                  tree: [],
                },
              ],
            },
          ],
        },
        {
          type: 'tree',
          name: 'ee',
          tree: [
            {
              type: 'tree',
              name: 'lib',
              tree: [
                {
                  type: 'tree',
                  name: 'ee',
                  tree: [
                    {
                      type: 'tree',
                      name: 'gitlab',
                      tree: [
                        {
                          type: 'tree',
                          name: 'checks',
                          tree: [
                            {
                              type: 'tree',
                              name: 'longtreenametomakepath',
                              tree: [
                                {
                                  type: 'blob',
                                  name: 'diff_check.rb',
                                  tree: [],
                                },
                              ],
                            },
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
        {
          type: 'tree',
          name: 'spec',
          tree: [
            {
              type: 'tree',
              name: 'javascripts',
              tree: [],
            },
            {
              type: 'blob',
              name: 'index_spec.js',
              tree: [],
            },
          ],
        },
      ];
      const flattened = utils.flattenTree(tree);

      expect(flattened).toEqual([
        {
          type: 'tree',
          name: 'app/javascripts',
          tree: [
            {
              type: 'blob',
              name: 'index.js',
              tree: [],
            },
          ],
        },
        {
          type: 'tree',
          name: 'ee/lib/…/…/…/longtreenametomakepath',
          tree: [
            {
              name: 'diff_check.rb',
              tree: [],
              type: 'blob',
            },
          ],
        },
        {
          type: 'tree',
          name: 'spec',
          tree: [
            {
              type: 'tree',
              name: 'javascripts',
              tree: [],
            },
            {
              type: 'blob',
              name: 'index_spec.js',
              tree: [],
            },
          ],
        },
      ]);
    });
  });

  describe('convertExpandLines', () => {
    it('converts expanded lines to normal lines', () => {
      const diffLines = [
        {
          type: 'match',
          old_line: 1,
          new_line: 1,
        },
        {
          type: '',
          old_line: 2,
          new_line: 2,
        },
      ];

      const lines = utils.convertExpandLines({
        diffLines,
        data: [{ text: 'expanded' }],
        typeKey: 'type',
        oldLineKey: 'old_line',
        newLineKey: 'new_line',
        mapLine: ({ line, oldLine, newLine }) => ({
          ...line,
          old_line: oldLine,
          new_line: newLine,
        }),
      });

      expect(lines).toEqual([
        {
          text: 'expanded',
          new_line: 1,
          old_line: 1,
          discussions: [],
          hasForm: false,
        },
        {
          type: '',
          old_line: 2,
          new_line: 2,
        },
      ]);
    });
  });

  describe('getDefaultWhitespace', () => {
    it('defaults to true if querystring and cookie are undefined', () => {
      expect(utils.getDefaultWhitespace()).toBe(true);
    });

    it('returns false if querystring is `1`', () => {
      expect(utils.getDefaultWhitespace('1', '0')).toBe(false);
    });

    it('returns true if querystring is `0`', () => {
      expect(utils.getDefaultWhitespace('0', undefined)).toBe(true);
    });

    it('returns false if cookie is `1`', () => {
      expect(utils.getDefaultWhitespace(undefined, '1')).toBe(false);
    });

    it('returns true if cookie is `0`', () => {
      expect(utils.getDefaultWhitespace(undefined, '0')).toBe(true);
    });
  });

  describe('isAdded', () => {
    it.each`
      type               | expected
      ${'new'}           | ${true}
      ${'new-nonewline'} | ${true}
      ${'old'}           | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isAdded({ type })).toBe(expected);
    });
  });

  describe('isRemoved', () => {
    it.each`
      type               | expected
      ${'old'}           | ${true}
      ${'old-nonewline'} | ${true}
      ${'new'}           | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isRemoved({ type })).toBe(expected);
    });
  });

  describe('isUnchanged', () => {
    it.each`
      type     | expected
      ${null}  | ${true}
      ${'new'} | ${false}
      ${'old'} | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isUnchanged({ type })).toBe(expected);
    });
  });

  describe('isMeta', () => {
    it.each`
      type               | expected
      ${'match'}         | ${true}
      ${'new-nonewline'} | ${true}
      ${'old-nonewline'} | ${true}
      ${'new'}           | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isMeta({ type })).toBe(expected);
    });
  });

  describe('parallelizeDiffLines', () => {
    it('converts inline diff lines to parallel diff lines', () => {
      const file = getDiffFileMock();

      expect(utils.parallelizeDiffLines(file.highlighted_diff_lines)).toEqual(
        file.parallel_diff_lines,
      );
    });

    /**
     * What's going on here?
     *
     * The inline version of parallelizeDiffLines simply keeps the difflines
     * in the same order they are received as opposed to shuffling them
     * to be "side by side".
     *
     * This keeps the underlying data structure the same which simplifies
     * the components, but keeps the changes grouped together as users
     * expect when viewing changes inline.
     */
    it('converts inline diff lines to inline diff lines with a parallel structure', () => {
      const file = getDiffFileMock();
      const files = utils.parallelizeDiffLines(file.highlighted_diff_lines, true);

      expect(files[5].left).toEqual(file.parallel_diff_lines[5].left);
      expect(files[5].right).toBeNull();
      expect(files[6].left).toBeNull();
      expect(files[6].right).toEqual(file.parallel_diff_lines[5].right);
    });
  });
});
