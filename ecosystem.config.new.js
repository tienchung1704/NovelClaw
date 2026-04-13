module.exports = {
  apps: [
    {
      name: 'novelclaw-portal',
      script: '/home/netviet/projects/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8010',
      cwd: '/home/netviet/projects/NovelClaw/apps/auth-portal/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/projects/NovelClaw/apps/auth-portal/local_web_portal:/home/netviet/projects/NovelClaw/apps/auth-portal'
      }
    },
    {
      name: 'novelclaw-multiagent',
      script: '/home/netviet/projects/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8011',
      cwd: '/home/netviet/projects/NovelClaw/apps/multiagent/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/projects/NovelClaw/apps/multiagent/local_web_portal:/home/netviet/projects/NovelClaw/apps/multiagent'
      }
    },
    {
      name: 'novelclaw-main',
      script: '/home/netviet/projects/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8012',
      cwd: '/home/netviet/projects/NovelClaw/apps/novelclaw/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/projects/NovelClaw/apps/novelclaw/local_web_portal:/home/netviet/projects/NovelClaw/apps/novelclaw'
      }
    }
  ]
};
