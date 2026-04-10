import type { ExtensionAPI } from '@mariozechner/pi-coding-agent';
import { registerContext7Tools } from './tools';

export default function context7Extension(pi: ExtensionAPI) {
  registerContext7Tools(pi);
}
