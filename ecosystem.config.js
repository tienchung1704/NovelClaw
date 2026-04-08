module.exports = {
  apps: [
    {
      name: 'novelclaw-portal',
      script: '/home/netviet/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8010',
      cwd: '/home/netviet/NovelClaw/apps/auth-portal/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/NovelClaw/apps/auth-portal/local_web_portal:/home/netviet/NovelClaw/apps/auth-portal'
      }
    },
    {
      name: 'novelclaw-multiagent',
      script: '/home/netviet/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8011 --root-path /multiagent',
      cwd: '/home/netviet/NovelClaw/apps/multiagent/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/NovelClaw/apps/multiagent/local_web_portal:/home/netviet/NovelClaw/apps/multiagent'
      }
    },
    {
      name: 'novelclaw-main',
      script: '/home/netviet/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8012 --root-path /claw',
      cwd: '/home/netviet/NovelClaw/apps/novelclaw/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/NovelClaw/apps/novelclaw/local_web_portal:/home/netviet/NovelClaw/apps/novelclaw'
      }
    }
  ]
};
