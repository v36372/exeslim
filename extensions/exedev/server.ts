import { defineExtension, section } from '@earendil-works/pi-durable'
import type { ExtensionHost } from '/home/exedev/ultimate/server/extensions.ts'

const guidance = `## exe.dev
This host is an exe.dev VM. Discover it before guessing:
- \`curl -s https://reflection.int.exe.xyz/\` gives this VM's name, owner, tags, comment and proxy port; \`/integrations\` lists attached integrations, each with a \`help\` line saying how to use it (keyless LLM gateways, HTTP proxies, GitHub repos). Use an integration instead of asking for a secret.
- \`ssh exe.dev <command>\` manages the user's VMs (\`help\`, \`ls\`, \`new\`, \`rm\`, \`cp\`, \`restart\`, \`resize\`, \`tag\`, \`comment\`, \`share\`, \`whoami\`); \`ssh <vm>.exe.xyz\` reaches the shell of a VM. This VM's key is tag-scoped: \`new --tag=<the user's tag>\` and \`rm\` work (tested), but it cannot list or change integrations (\`int\`), so ask the user for that. Quote flag values with spaces: \`"--comment='a note'"\`.
- Ask before creating, deleting, resizing or sharing a VM.
- Docs: https://exe.dev/llms.txt (agents), \`ssh exe.dev doc\`.`

// The private exe.dev edge authenticates users; nginx also restricts the owner.
export default function exedev(host: ExtensionHost) {
  const origin = process.env.ULTIMATE_EXE_ORIGIN
  const owner = process.env.ULTIMATE_EXE_OWNER
  if (!origin || !owner) throw new Error('exe.dev access configuration is missing')
  let remove: (() => void) | undefined
  host.onOpen(async () => {
    remove = host.access.allow({
      origin,
      verify: ({ headers }) => {
        const email = headers['x-exedev-email']
        const id = headers['x-exedev-userid']
        return email === owner && typeof id === 'string' && id ? { login: id } : undefined
      },
    })
  })
  host.onClose(async () => {
    remove?.()
  })
  return defineExtension({ name: 'exedev', sections: [section('exedev', () => guidance)] })
}
