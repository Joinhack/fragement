
#include "threadpool.h"

struct threadpool* threadpool_init(int thread_num, int queue_max_num)
{
  struct threadpool *pool = NULL;
  do
  {
    pool = (struct threadpool *) malloc(sizeof (struct threadpool));
    if (NULL == pool)
    {
		cout << ("failed to malloc threadpool!\n");
		break;
    }
    pool->thread_num = thread_num;
    pool->queue_max_num = queue_max_num;
    pool->queue_cur_num = 0;
    pool->head = NULL;
    pool->tail = NULL;
    if (pthread_mutex_init(&(pool->mutex), NULL))
    {
		cout << ("failed to init mutex!\n");
		break;
    }
    if (pthread_cond_init(&(pool->queue_empty), NULL))
    {
		cout << ("failed to init queue_empty!\n");
		break;
    }
    if (pthread_cond_init(&(pool->queue_not_empty), NULL))
    {
		cout << ("failed to init queue_not_empty!\n");
		break;
    }
    pool->pthreads = (pthread_t*) malloc(sizeof (pthread_t) * thread_num);
    if (NULL == pool->pthreads)
    {
		cout << ("failed to malloc pthreads!\n");
		break;
    }
    pool->queue_close = 0;
    pool->pool_close = 0;
    int i;
    for (i = 0; i < pool->thread_num; ++i)
    {
		pthread_create(&(pool->pthreads[i]), NULL, threadpool_function, (void *) pool);
    }

    return pool;
  } while (0);

  return NULL;
}

int my_threadpool_add_job(struct threadpool* pool, threadjob callback_function, void *arg)
{
	assert(pool != NULL);
	assert(callback_function != NULL);
	assert(arg != NULL);


	if (pool->queue_cur_num >= pool->queue_max_num) //不能超过最带队列
	{
		return -1;
	}

	if (pool->queue_close || pool->pool_close) //队列关闭或者线程池关闭就退出
	{
		return -1;
	}
	pthread_mutex_lock(&(pool->mutex));
	struct job *pjob = (struct job*) malloc(sizeof (struct job));
	if (NULL == pjob)
	{
		pthread_mutex_unlock(&(pool->mutex));
		return -1;
	}
	pjob->callback_function = callback_function;
	pjob->arg = arg;
	pjob->next = NULL;
	if (pool->head == NULL)
	{
		pool->head = pool->tail = pjob;
	} else
	{
		pool->tail->next = pjob;
		pool->tail = pjob;
	}
	pool->queue_cur_num++;
	pthread_cond_signal(&(pool->queue_not_empty)); //队列空的时候，有任务来时就通知线程池中的线程：队列非空
	pthread_mutex_unlock(&(pool->mutex));
	return 0;
}

int threadpool_add_job(struct threadpool* pool, threadjob callback_function, void *arg)
{
	if (0 != my_threadpool_add_job(pool, callback_function, arg))
	{
		//cout << "quene full !!!!!!!!!add failed!" << endl;
		return -1;
	}

	//cout << "insert ok!!" << (char*) arg << endl;
	return 0;
}

void* threadpool_function(void* arg)
{
  struct threadpool *pool = (struct threadpool*) arg;
  struct job *pjob = NULL;
  while (1) //死循环
  {
    pthread_mutex_lock(&(pool->mutex));
    while ((pool->queue_cur_num == 0) && !pool->pool_close) //队列为空时，就等待队列非空
    {
		//cout << "wait！！" << endl;
		pthread_cond_wait(&(pool->queue_not_empty), &(pool->mutex));
		//cout << "a task come！" << endl;

    }
    if (pool->pool_close) //线程池关闭，线程就退出
    {
		pthread_mutex_unlock(&(pool->mutex));
		//cout << "thread quit！！！" << endl;
		pthread_exit(NULL);
    }

    //cout<<""<<endl;
    if (pool->queue_cur_num >= 1)
    {
		pool->queue_cur_num--;
		pjob = pool->head;
		//cout << "当前队列里面有" << pool->queue_cur_num + 1 << "个,取出来第" << (char*) pjob->arg << "个" << endl;
		if (pool->queue_cur_num == 0)
		{
		pool->head = pool->tail = NULL;
		} 
		else
		{
		pool->head = pjob->next;
		}
		if (pool->queue_cur_num == 0)
		{
		pthread_cond_signal(&(pool->queue_empty)); //队列为空，就可以通知threadpool_destroy函数，销毁线程函数
		}

		pthread_mutex_unlock(&(pool->mutex));

		//cout << (char*) pjob->arg << "取出来啦！！！" << endl;
		(*(pjob->callback_function))(pjob->arg); //线程真正要做的工作，回调函数的调用
		//cout << (char*) pjob->arg << "分析完毕！！！" << endl;

		free(pjob);
		pjob = NULL;
    }
    else
        pthread_mutex_unlock(&(pool->mutex));
          
  }
  
 
}

int threadpool_destroy(struct threadpool *pool)
{
	assert(pool != NULL);
	pthread_mutex_lock(&(pool->mutex));
	if (pool->queue_close || pool->pool_close) //线程池已经退出了，就直接返回
	{
		pthread_mutex_unlock(&(pool->mutex));
		return -1;
	}

	pool->queue_close = 1; //置队列关闭标志
	while (pool->queue_cur_num != 0)
	{
		pthread_cond_wait(&(pool->queue_empty), &(pool->mutex)); //等待队列为空
	}

	pool->pool_close = 1; //置线程池关闭标志
	pthread_mutex_unlock(&(pool->mutex));
	//cout<<"signaaa"<<endl;
	pthread_cond_broadcast(&(pool->queue_not_empty)); //唤醒线程池中正在阻塞的线程
	//pthread_cond_broadcast(&(pool->queue_not_full));   //唤醒添加任务的threadpool_add_job函数
	int i;
	for (i = 0; i < pool->thread_num; ++i)
	{
		pthread_join(pool->pthreads[i], NULL); //等待线程池的所有线程执行完毕
	}

	pthread_mutex_destroy(&(pool->mutex)); //清理资源
	pthread_cond_destroy(&(pool->queue_empty));
	pthread_cond_destroy(&(pool->queue_not_empty));

	free(pool->pthreads);
	struct job *p;
	while (pool->head != NULL)
	{
		p = pool->head;
		pool->head = p->next;
		free(p);
	}
	free(pool);
	return 0;
}
