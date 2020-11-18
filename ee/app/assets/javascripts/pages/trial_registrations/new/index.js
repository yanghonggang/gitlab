import '~/pages/sessions/index';

import LengthValidator from '~/pages/sessions/new/length_validator';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import NoEmojiValidator from '~/emoji/no_emoji_validator';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';
import UsernameSuggester from './username_suggester';

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new SigninTabsMemoizer(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new
new UsernameSuggester('new_user_username', ['new_user_first_name', 'new_user_last_name']); // eslint-disable-line no-new
